-- ============================================================
-- Script:      transaction_id_age_risk.sql
-- Category:    09_autovacuum_maintenance
-- Description: Identifies tables with high transaction ID (XID) age that are
--              at risk of transaction ID wraparound. PostgreSQL uses a 32-bit
--              transaction ID counter that wraps at ~2.1 billion. Tables that
--              have not been frozen within the autovacuum_freeze_max_age limit
--              risk data corruption. This script provides a risk-rated list.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/09_autovacuum_maintenance/transaction_id_age_risk.sql
--
-- Output Columns:
--   schemaname          - Schema name
--   tablename           - Table name
--   xid_age             - Age of oldest unfrozen XID in the table
--   freeze_max_age      - Configured autovacuum_freeze_max_age setting
--   freeze_pct_used     - Percentage of freeze budget consumed
--   risk_level          - CRITICAL / HIGH / MEDIUM / LOW based on age thresholds
--   last_autovacuum     - Last autovacuum timestamp (NULL if never)
--   last_vacuum         - Last manual vacuum timestamp (NULL if never)
--   table_size          - Table size for prioritization
--
-- Dependencies:
--   - pg_class, pg_stat_user_tables (always available)
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - CRITICAL: xid_age > 1.8B — database will shut down at 2B! Run VACUUM FREEZE immediately.
--   - HIGH:     xid_age > 1.5B — urgent autovacuum tuning or manual VACUUM FREEZE needed.
--   - MEDIUM:   xid_age > 1.0B — monitor closely and tune autovacuum thresholds.
--   - LOW:      everything else — within safe operating range.
--   - PostgreSQL will automatically enter 'soft wraparound' (read-only mode) at ~2.1B XIDs.
--   - Manual override: VACUUM FREEZE <schemaname>.<tablename>;
--   - Database-level age: SELECT datname, age(datfrozenxid) FROM pg_database ORDER BY 2 DESC;
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

WITH freeze_settings AS (
    SELECT
        current_setting('autovacuum_freeze_max_age')::bigint AS freeze_max_age,
        200000000::bigint                                     AS critical_threshold,
        150000000::bigint                                     AS high_threshold,
        100000000::bigint                                     AS medium_threshold
)
SELECT
    n.nspname                                        AS schemaname,
    c.relname                                        AS tablename,
    age(c.relfrozenxid)                              AS xid_age,
    fs.freeze_max_age,
    round(
        100.0 * age(c.relfrozenxid) / fs.freeze_max_age, 1
    )                                                AS freeze_pct_used,
    CASE
        WHEN age(c.relfrozenxid) > 1800000000 THEN 'CRITICAL'
        WHEN age(c.relfrozenxid) > 1500000000 THEN 'HIGH'
        WHEN age(c.relfrozenxid) > fs.freeze_max_age THEN 'MEDIUM'
        ELSE 'LOW'
    END                                              AS risk_level,
    t.last_autovacuum,
    t.last_vacuum,
    pg_size_pretty(pg_table_size(c.oid))             AS table_size
FROM pg_class c
JOIN pg_namespace          n  ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables t ON t.relid = c.oid
CROSS JOIN freeze_settings fs
WHERE c.relkind = 'r'                                -- regular tables only
  AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND age(c.relfrozenxid) > fs.freeze_max_age * 0.5 -- show tables > 50% of freeze budget
ORDER BY xid_age DESC
LIMIT 50;

-- Database-level XID age summary
SELECT '---' AS section;
SELECT 'DATABASE-LEVEL XID AGE (MOST CRITICAL METRIC)' AS section;

SELECT
    datname,
    age(datfrozenxid)                               AS db_xid_age,
    CASE
        WHEN age(datfrozenxid) > 1800000000 THEN 'CRITICAL'
        WHEN age(datfrozenxid) > 1500000000 THEN 'HIGH'
        WHEN age(datfrozenxid) > 200000000  THEN 'MEDIUM'
        ELSE 'LOW'
    END                                             AS risk_level
FROM pg_database
WHERE datallowconn
ORDER BY db_xid_age DESC;
