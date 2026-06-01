-- ============================================================
-- Script:      top_slow_queries.sql
-- Category:    01_query_performance
-- Description: Top 25 slowest queries by total execution time from
--              pg_stat_statements, with per-call averages and I/O stats.
--
-- Usage:       psql -h <host> -U <user> -d <database> -f scripts/01_query_performance/top_slow_queries.sql
--
--              Optional: Set the number of top queries to return
--              \set top_n 25
--
-- Parameters:
--   top_n  (default: 25)  Number of top queries to return
--
-- Output Columns:
--   rank            - Query rank by total time
--   total_time_sec  - Total cumulative execution time in seconds
--   avg_time_ms     - Average execution time per call in milliseconds
--   calls           - Total number of times the query was called
--   rows_per_call   - Average rows returned per call
--   shared_blks_hit - Shared buffer hits
--   shared_blks_read- Physical block reads from disk
--   query           - Normalized query text (constants replaced with $1, $2, ...)
--   dbname          - Database name
--   username        - Role that executed the query
--
-- Dependencies:
--   - pg_stat_statements extension must be installed and enabled
--   - shared_preload_libraries = 'pg_stat_statements' in postgresql.conf
--   - Requires pg_monitor role or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - Results reflect cumulative stats since last pg_stat_statements reset.
--   - Use pg_stat_statements_reset() to clear stats (requires superuser).
--   - For I/O timing breakdown, ensure track_io_timing = on in postgresql.conf.
--   - In PG17+, queryid is stable across databases for the same query shape.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

\set top_n 25

SELECT
    row_number() OVER (ORDER BY total_exec_time DESC)   AS rank,
    round(total_exec_time::numeric / 1000, 2)           AS total_time_sec,
    round((mean_exec_time)::numeric, 2)                 AS avg_time_ms,
    calls,
    round(rows::numeric / NULLIF(calls, 0), 1)          AS rows_per_call,
    shared_blks_hit,
    shared_blks_read,
    round(
        100.0 * shared_blks_hit
        / NULLIF(shared_blks_hit + shared_blks_read, 0), 1
    )                                                   AS cache_hit_pct,
    round(total_exec_time::numeric / NULLIF(calls, 0) / 1000, 4)
                                                        AS avg_time_sec,
    d.datname                                           AS dbname,
    r.rolname                                           AS username,
    left(regexp_replace(query, E'\\s+', ' ', 'g'), 120) AS query
FROM pg_stat_statements pss
JOIN pg_database d ON d.oid = pss.dbid
JOIN pg_roles    r ON r.oid = pss.userid
WHERE calls > 0
  AND query NOT ILIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT :top_n;
