-- ============================================================
-- Script:      freeze_wraparound_risk.sql
-- Category:    03_vacuum_bloat
-- Description: Emergency script to identify tables and databases at risk of
--              transaction ID (XID) wraparound. PostgreSQL uses a circular
--              32-bit XID space (~2.1 billion). When a table's oldest XID
--              approaches the wraparound limit, PostgreSQL will:
--              1. Force aggressive autovacuum (at autovacuum_freeze_max_age)
--              2. Refuse new connections (at ~1.6B XIDs ahead in PG15+)
--              3. Shut down the database for safety (at 2B XIDs)
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/03_vacuum_bloat/freeze_wraparound_risk.sql
--
-- Output Sections:
--   1. Tables approaching wraparound (sorted by age, most dangerous first)
--   2. Database-level freeze status
--   3. Estimated time to wraparound (requires xid generation rate estimate)
--
-- Dependencies:
--   - pg_class, pg_namespace (always available)
--   - pg_stat_user_tables (always available)
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - EMERGENCY: If xid_age > 1,900,000,000, immediately run:
--     VACUUM FREEZE VERBOSE <schemaname>.<tablename>;
--   - WARNING: If xid_age > 1,500,000,000, schedule VACUUM FREEZE within 24 hours.
--   - CAUTION: If xid_age > 500,000,000, review and tune autovacuum settings.
--   - Run on ALL databases in the cluster — each database has its own age.
--   - Also see: transaction_id_age_risk.sql in 09_autovacuum_maintenance/
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Section 1: Table-level wraparound risk
SELECT 'TABLE-LEVEL WRAPAROUND RISK (TOP 30 MOST DANGEROUS)' AS section;

SELECT
    n.nspname                                        AS schema_name,
    c.relname                                        AS table_name,
    age(c.relfrozenxid)                              AS xid_age,
    2000000000 - age(c.relfrozenxid)                 AS xids_until_wraparound,
    CASE
        WHEN age(c.relfrozenxid) > 1900000000 THEN '🔴 EMERGENCY - VACUUM FREEZE NOW!'
        WHEN age(c.relfrozenxid) > 1500000000 THEN '🟠 CRITICAL - VACUUM FREEZE THIS WEEK'
        WHEN age(c.relfrozenxid) > 750000000  THEN '🟡 HIGH - REVIEW AUTOVACUUM SETTINGS'
        WHEN age(c.relfrozenxid) > 500000000  THEN '🔵 MEDIUM - MONITOR CLOSELY'
        ELSE                                         '🟢 LOW - WITHIN SAFE RANGE'
    END                                              AS risk_status,
    pg_size_pretty(pg_table_size(c.oid))             AS table_size,
    t.last_autovacuum,
    t.last_vacuum
FROM pg_class c
JOIN pg_namespace          n  ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables t ON t.relid = c.oid
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY age(c.relfrozenxid) DESC
LIMIT 30;

-- Section 2: Database-level freeze status (MOST CRITICAL CHECK)
SELECT '---' AS section;
SELECT 'DATABASE-LEVEL WRAPAROUND STATUS (RUN ACROSS ALL DATABASES)' AS section;

SELECT
    datname,
    age(datfrozenxid)                               AS db_xid_age,
    2000000000 - age(datfrozenxid)                  AS xids_remaining,
    pg_size_pretty(pg_database_size(oid))           AS database_size,
    CASE
        WHEN age(datfrozenxid) > 1900000000 THEN '🔴 EMERGENCY'
        WHEN age(datfrozenxid) > 1500000000 THEN '🟠 CRITICAL'
        WHEN age(datfrozenxid) > 750000000  THEN '🟡 HIGH'
        WHEN age(datfrozenxid) > 500000000  THEN '🔵 MEDIUM'
        ELSE                                         '🟢 LOW'
    END                                             AS risk_status
FROM pg_database
WHERE datallowconn
ORDER BY db_xid_age DESC;

-- Section 3: Current autovacuum freeze settings
SELECT '---' AS section;
SELECT 'AUTOVACUUM FREEZE CONFIGURATION' AS section;

SELECT
    name,
    setting,
    unit
FROM pg_settings
WHERE name IN (
    'autovacuum_freeze_max_age',
    'vacuum_freeze_min_age',
    'vacuum_freeze_table_age',
    'autovacuum_vacuum_cost_delay',
    'autovacuum_max_workers'
)
ORDER BY name;
