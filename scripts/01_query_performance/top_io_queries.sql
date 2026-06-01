-- ============================================================
-- Script:      top_io_queries.sql
-- Category:    01_query_performance
-- Description: Top 20 queries ranked by total physical I/O (block reads from disk).
--              Queries at the top are the primary drivers of disk I/O and are
--              candidates for index optimization, sequential scan elimination,
--              or query rewriting to reduce physical I/O.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/01_query_performance/top_io_queries.sql
--
--              Requires: track_io_timing = on for timing columns to be non-zero
--
-- Output Columns:
--   rank              - Query rank by total physical block reads
--   shared_blks_read  - Total physical blocks read from disk (most important metric)
--   shared_blks_hit   - Total shared buffer hits (no disk I/O)
--   blk_read_pct      - Percentage of accesses that required disk I/O (lower = better)
--   read_time_sec     - Total I/O read time in seconds (requires track_io_timing=on)
--   calls             - Total query executions
--   avg_io_ms         - Average I/O read time per call in milliseconds
--   total_time_sec    - Total execution time in seconds
--   rows_per_call     - Average rows returned per call
--   query             - Normalized query text
--
-- Dependencies:
--   - pg_stat_statements extension must be installed
--   - track_io_timing = on recommended (in postgresql.conf)
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - High shared_blks_read with low blk_read_pct suggests warm cache (good).
--   - High shared_blks_read with high blk_read_pct (>10%) suggests:
--     * Index is missing → sequential scan
--     * Table too large for shared_buffers → I/O bottleneck
--     * Query runs infrequently → cold cache is expected
--   - blk_read_pct < 1% is healthy for OLTP.
--   - Compare with top_slow_queries.sql: high-I/O queries are not always slow.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    row_number() OVER (ORDER BY shared_blks_read DESC) AS rank,
    shared_blks_read,
    shared_blks_hit,
    round(
        100.0 * shared_blks_read
        / NULLIF(shared_blks_read + shared_blks_hit, 0), 2
    )                                                AS blk_read_pct,
    round(blk_read_time::numeric / 1000, 2)          AS read_time_sec,
    calls,
    round(blk_read_time::numeric / NULLIF(calls, 0), 2)
                                                     AS avg_io_ms,
    round(total_exec_time::numeric / 1000, 2)        AS total_time_sec,
    round(rows::numeric / NULLIF(calls, 0), 1)       AS rows_per_call,
    d.datname                                        AS dbname,
    left(regexp_replace(query, E'\\s+', ' ', 'g'), 120) AS query
FROM pg_stat_statements pss
JOIN pg_database d ON d.oid = pss.dbid
WHERE shared_blks_read > 0
  AND calls > 0
  AND query NOT ILIKE '%pg_stat%'
ORDER BY shared_blks_read DESC
LIMIT 20;
