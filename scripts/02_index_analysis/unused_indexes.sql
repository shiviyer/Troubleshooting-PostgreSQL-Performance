-- ============================================================
-- Script:      unused_indexes.sql
-- Category:    02_index_analysis
-- Description: Identifies indexes that have never been scanned (or rarely used)
--              since the last statistics reset. These are candidates for removal
--              to reduce write overhead, storage, and autovacuum work.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/02_index_analysis/unused_indexes.sql
--
-- Output Columns:
--   schemaname    - Schema containing the table and index
--   tablename     - Table the index belongs to
--   indexname     - Index name
--   index_size    - Index size on disk (human-readable)
--   index_scans   - Number of index scans since last stats reset
--   table_writes  - Combined inserts+updates+deletes (write amplification indicator)
--   idx_def       - Index definition (CREATE INDEX statement)
--
-- Dependencies:
--   - pg_stat_user_indexes (always available)
--   - pg_index, pg_class, pg_indexes, pg_statio_user_indexes
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - CAUTION: Do NOT drop indexes without verifying:
--     1. Stats have not been reset recently (check pg_stat_bgwriter.stats_reset)
--     2. Index is not used by a constraint (UNIQUE, PRIMARY KEY, EXCLUDE)
--     3. Index is not a partial index used in rare but critical queries
--     4. Index is not used by standby/replica queries (check pg_stat_user_indexes on standbys)
--   - DROP CONCURRENTLY is safe on production: DROP INDEX CONCURRENTLY <indexname>;
--   - Filter by index_scans = 0 for completely unused; adjust for rarely used.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    s.schemaname,
    s.relname                                    AS tablename,
    s.indexrelname                               AS indexname,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
    s.idx_scan                                   AS index_scans,
    (t.n_tup_ins + t.n_tup_upd + t.n_tup_del)   AS table_writes,
    x.indisunique                                AS is_unique,
    x.indisprimary                               AS is_primary,
    i.indexdef                                   AS idx_def
FROM pg_stat_user_indexes s
JOIN pg_index       x  ON x.indexrelid = s.indexrelid
JOIN pg_stat_user_tables t ON t.relid = s.relid
JOIN pg_indexes     i  ON i.schemaname = s.schemaname
                       AND i.tablename  = s.relname
                       AND i.indexname  = s.indexrelname
WHERE s.idx_scan < 5                             -- fewer than 5 scans since reset
  AND NOT x.indisunique                          -- exclude unique/PK constraints
  AND NOT x.indisprimary
  AND pg_relation_size(s.indexrelid) > 0
ORDER BY pg_relation_size(s.indexrelid) DESC,
         s.idx_scan ASC;
