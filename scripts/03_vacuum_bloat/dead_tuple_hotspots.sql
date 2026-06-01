-- ============================================================
-- Script:      dead_tuple_hotspots.sql
-- Category:    03_vacuum_bloat
-- Description: Identifies tables with the highest dead tuple counts and ratios.
--              Dead tuples accumulate from UPDATE and DELETE operations and are
--              not cleaned up until VACUUM runs. High dead tuple counts cause
--              table bloat, sequential scan slowdowns, and index bloat.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/03_vacuum_bloat/dead_tuple_hotspots.sql
--
-- Output Columns:
--   schemaname        - Schema name
--   tablename         - Table name
--   dead_tuples       - Estimated number of dead tuples (from pg_stat_user_tables)
--   live_tuples       - Estimated number of live tuples
--   dead_ratio_pct    - Dead tuples as a percentage of total tuples
--   table_size        - Table size on disk (heap only, no indexes)
--   last_autovacuum   - Last time autovacuum ran on this table
--   last_vacuum       - Last time manual VACUUM ran on this table
--   n_mod_since_analyze - Rows modified since last ANALYZE
--
-- Dependencies:
--   - pg_stat_user_tables (always available)
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - Values are estimates from the visibility map; use pgstattuple for precise counts.
--   - Tables with dead_ratio_pct > 20% are candidates for immediate VACUUM.
--   - Tables with dead_ratio_pct > 50% may have autovacuum issues; investigate.
--   - Run after high-volume bulk updates/deletes to identify cleanup needs.
--   - If last_autovacuum is NULL or very old, check autovacuum configuration.
--
-- Related Scripts:
--   - vacuum_progress_monitor.sql  — Monitor running VACUUM
--   - autovacuum_worker_status.sql — Check if autovacuum is running
--   - tables_needing_vacuum.sql    — Tables approaching thresholds
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    schemaname,
    relname                                              AS tablename,
    n_dead_tup                                          AS dead_tuples,
    n_live_tup                                          AS live_tuples,
    round(
        100.0 * n_dead_tup
        / NULLIF(n_live_tup + n_dead_tup, 0), 1
    )                                                   AS dead_ratio_pct,
    pg_size_pretty(pg_relation_size(schemaname || '.' || relname))
                                                        AS table_size,
    last_autovacuum,
    last_vacuum,
    n_mod_since_analyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000                                  -- filter trivial tables
ORDER BY n_dead_tup DESC
LIMIT 40;
