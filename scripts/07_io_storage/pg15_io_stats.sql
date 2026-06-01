-- ============================================================
-- Script:      pg15_io_stats.sql
-- Category:    07_io_storage
-- Description: Queries the pg_stat_io view introduced in PostgreSQL 15 to provide
--              detailed I/O accounting by backend type, I/O object, and I/O context.
--              This is the definitive source for understanding WHERE PostgreSQL is
--              doing I/O and how efficiently it is using its buffer pool.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/07_io_storage/pg15_io_stats.sql
--
-- Output Columns:
--   backend_type  - Type of backend (client backend, autovacuum, bgwriter, etc.)
--   object        - I/O object type (relation, WAL, temp relation, etc.)
--   context       - I/O context (normal, vacuum, bulkread, bulkwrite)
--   reads         - Number of read I/O operations (physical reads from disk)
--   read_bytes    - Bytes read from disk (hits not counted)
--   writes        - Number of write I/O operations
--   write_bytes   - Bytes written to disk
--   extends       - Block extensions (file growth)
--   hits          - Buffer pool hits (no disk I/O)
--   hit_pct       - Cache hit percentage for this backend_type/object/context
--   evictions     - Shared buffer evictions
--   reuses        - Buffer reuses (for temp relations)
--   fsyncs        - fsync calls
--
-- Dependencies:
--   - pg_stat_io (PostgreSQL 15+)
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - MINIMUM VERSION: PostgreSQL 15
--   - In PG18, pg_stat_io is expanded to include async I/O statistics.
--   - Zero values are filtered out; only active I/O types are shown.
--   - 'bulkread' context = sequential scans; 'normal' = index/random reads.
--   - Low hit_pct for 'normal' context indicates shared_buffers too small.
--   - High evictions relative to reads indicates buffer churn.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Verify PostgreSQL version
DO $$
BEGIN
  IF current_setting('server_version_num')::int < 150000 THEN
    RAISE EXCEPTION 'pg_stat_io requires PostgreSQL 15 or later. Current version: %',
      current_setting('server_version');
  END IF;
END $$;

SELECT
    backend_type,
    object,
    context,
    reads,
    pg_size_pretty(reads * op_bytes)                 AS read_bytes,
    writes,
    pg_size_pretty(writes * op_bytes)                AS write_bytes,
    extends,
    hits,
    round(
        100.0 * hits / NULLIF(hits + reads, 0), 2
    )                                                AS hit_pct,
    evictions,
    reuses,
    fsyncs,
    stats_reset
FROM pg_stat_io
WHERE (reads + writes + extends + hits) > 0         -- filter empty rows
ORDER BY reads DESC, backend_type, object, context;

-- Summary by backend type
SELECT '--- SUMMARY BY BACKEND TYPE ---' AS summary;

SELECT
    backend_type,
    sum(reads)                                        AS total_reads,
    sum(writes)                                       AS total_writes,
    sum(hits)                                         AS total_hits,
    round(
        100.0 * sum(hits) / NULLIF(sum(hits) + sum(reads), 0), 2
    )                                                 AS overall_hit_pct,
    sum(evictions)                                    AS total_evictions,
    sum(fsyncs)                                       AS total_fsyncs
FROM pg_stat_io
GROUP BY backend_type
ORDER BY total_reads DESC;
