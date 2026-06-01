-- ============================================================
-- Script:      cache_hit_rate_global.sql
-- Category:    08_memory_caching
-- Description: Shows global and per-database buffer cache hit ratios.
--              The cache hit rate is the most fundamental shared_buffers
--              performance indicator. A global hit rate below 90% on an
--              OLTP workload may indicate shared_buffers is undersized.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/08_memory_caching/cache_hit_rate_global.sql
--
-- Output Columns:
--   Section 1 (Global):
--     heap_read       - Physical block reads from disk (heap/table blocks)
--     heap_hit        - Buffer pool hits for heap blocks
--     index_read      - Physical index block reads from disk
--     index_hit       - Buffer pool hits for index blocks
--     heap_hit_pct    - Heap (table) cache hit percentage
--     index_hit_pct   - Index cache hit percentage
--     overall_hit_pct - Combined heap+index cache hit percentage
--
--   Section 2 (Per Database):
--     datname         - Database name
--     blks_read       - Physical reads from disk
--     blks_hit        - Buffer pool hits
--     hit_pct         - Cache hit percentage for this database
--     xact_commit     - Committed transactions (activity indicator)
--
-- Dependencies:
--   - pg_stat_bgwriter (always available) — global stats
--   - pg_stat_database (always available) — per-database stats
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - Values accumulate since last stats reset (pg_stat_bgwriter.stats_reset).
--   - Global hit rate < 90% on OLTP: consider increasing shared_buffers.
--   - Global hit rate < 99% on OLAP/data warehouse: expected; analyze query plans.
--   - Newly restarted servers will show low hit rates until the buffer pool warms up.
--   - Use pg_buffercache extension for real-time buffer occupancy analysis.
--   - Use pg15_io_stats.sql for per-backend-type breakdown (PG15+).
--
-- Related Scripts:
--   - shared_buffer_usage.sql          — pg_buffercache breakdown
--   - table_cache_hit_rate.sql         — Per-table cache hit rates
--   - pg_buffercache_top_relations.sql — Top relations in shared_buffers
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Section 1: Global cache hit rate
SELECT 'GLOBAL BUFFER CACHE HIT RATE' AS section;

SELECT
    sum(heap_blks_read)                              AS heap_read,
    sum(heap_blks_hit)                               AS heap_hit,
    sum(idx_blks_read)                               AS index_read,
    sum(idx_blks_hit)                                AS index_hit,
    round(
        100.0 * sum(heap_blks_hit)
        / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
    )                                                AS heap_hit_pct,
    round(
        100.0 * sum(idx_blks_hit)
        / NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2
    )                                                AS index_hit_pct,
    round(
        100.0 * (sum(heap_blks_hit) + sum(idx_blks_hit))
        / NULLIF(
            sum(heap_blks_hit) + sum(heap_blks_read)
            + sum(idx_blks_hit) + sum(idx_blks_read), 0
        ), 2
    )                                                AS overall_hit_pct
FROM pg_statio_user_tables;

-- Section 2: Per-database cache hit rate
SELECT '---' AS section;
SELECT 'PER-DATABASE CACHE HIT RATE' AS section;

SELECT
    datname                                          AS database,
    blks_read,
    blks_hit,
    round(
        100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2
    )                                                AS hit_pct,
    xact_commit                                      AS committed_txns,
    xact_rollback                                    AS rolled_back_txns,
    stats_reset
FROM pg_stat_database
WHERE datname NOT IN ('template0', 'template1')
ORDER BY blks_read DESC;

-- Section 3: Current shared_buffers setting
SELECT '---' AS section;
SELECT 'SHARED_BUFFERS CONFIGURATION' AS section;

SELECT
    current_setting('shared_buffers')               AS shared_buffers,
    pg_size_pretty(
        current_setting('shared_buffers')::text::bigint * 8192
    )                                               AS shared_buffers_size,
    current_setting('effective_cache_size')         AS effective_cache_size;
