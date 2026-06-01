-- ============================================================
-- Script:      replication_slot_lag.sql
-- Category:    06_replication_ha
-- Description: Monitors replication slot lag and WAL retention caused by
--              inactive or lagging slots. Replication slots prevent WAL
--              files from being deleted until the subscriber has consumed them.
--              An inactive or lagging slot can cause unbounded WAL accumulation,
--              leading to disk space exhaustion.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/06_replication_ha/replication_slot_lag.sql
--
-- Output Columns:
--   slot_name        - Replication slot name
--   slot_type        - physical or logical
--   active           - Whether the slot currently has a connected consumer
--   xmin_age         - Age of oldest transaction ID held by this slot
--   catalog_xmin_age - Age of oldest catalog XID held (logical slots only)
--   restart_lsn      - Oldest WAL LSN that must be retained for this slot
--   confirmed_lsn    - LSN last confirmed consumed by the subscriber
--   lag_bytes        - WAL bytes retained due to this slot
--   lag_size         - Human-readable WAL retention
--   database         - Target database (logical slots only)
--   plugin           - Logical decoder plugin name
--
-- Dependencies:
--   - pg_replication_slots (always available on primary)
--   - Run on the PRIMARY server
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - DANGER: inactive slots can cause unlimited WAL accumulation!
--   - Alert if: active = false AND lag_bytes > 1GB.
--   - Alert if: active = false AND slot has been inactive for hours.
--   - To drop an orphaned slot (IRREVERSIBLE):
--     SELECT pg_drop_replication_slot('slot_name');
--   - Confirm subscriber is truly gone before dropping logical slots.
--   - xmin_age > 0 means the slot is holding back VACUUM across the cluster.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    slot_name,
    slot_type,
    active,
    active_pid,
    COALESCE(age(xmin), 0)                           AS xmin_age,
    COALESCE(age(catalog_xmin), 0)                   AS catalog_xmin_age,
    restart_lsn,
    confirmed_flush_lsn,
    -- WAL retained by this slot
    CASE
        WHEN restart_lsn IS NOT NULL
        THEN pg_current_wal_lsn() - restart_lsn
        ELSE 0
    END                                              AS lag_bytes,
    CASE
        WHEN restart_lsn IS NOT NULL
        THEN pg_size_pretty(pg_current_wal_lsn() - restart_lsn)
        ELSE '0'
    END                                              AS lag_size,
    database,
    plugin,
    -- Risk assessment
    CASE
        WHEN NOT active AND (pg_current_wal_lsn() - restart_lsn) > 10737418240
        THEN '🔴 CRITICAL: >10GB WAL retained, slot is inactive!'
        WHEN NOT active AND (pg_current_wal_lsn() - restart_lsn) > 1073741824
        THEN '🟠 HIGH: >1GB WAL retained, slot is inactive'
        WHEN NOT active
        THEN '🟡 WARNING: Slot is inactive'
        ELSE '🟢 Active'
    END                                              AS status
FROM pg_replication_slots
ORDER BY lag_bytes DESC NULLS LAST, active ASC;

-- Summary: total WAL retained by all slots
SELECT '---' AS section;
SELECT 'TOTAL WAL RETAINED BY ALL REPLICATION SLOTS' AS section;

SELECT
    count(*)                                         AS total_slots,
    count(*) FILTER (WHERE active)                   AS active_slots,
    count(*) FILTER (WHERE NOT active)               AS inactive_slots,
    pg_size_pretty(
        sum(CASE
            WHEN restart_lsn IS NOT NULL
            THEN pg_current_wal_lsn() - restart_lsn
            ELSE 0
        END)
    )                                                AS total_wal_retained
FROM pg_replication_slots;
