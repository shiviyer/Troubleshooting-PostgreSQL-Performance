-- ============================================================
-- Script:      query_forensics.sql
-- Category:    01_query_performance
-- Description: Full forensic view of currently active and blocked queries,
--              showing backend state, lock info, wait events, and associated
--              pg_stat_statements data for resource consumption context.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/01_query_performance/query_forensics.sql
--
-- Output Columns:
--   pid           - Backend process ID
--   duration      - Elapsed query time
--   state         - Backend state
--   wait_event    - Wait event type/name
--   blocking_pids - PIDs that are blocking this backend (empty if unblocked)
--   lock_type     - Type of lock being waited on (if any)
--   calls         - Total call count from pg_stat_statements
--   avg_ms        - Average execution time (ms) from pg_stat_statements
--   username      - Executing role
--   dbname        - Database
--   query         - Query text (truncated)
--
-- Dependencies:
--   - pg_stat_statements extension recommended (gracefully degrades without it)
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - blocking_pids uses pg_blocking_pids() which is available in PG 9.6+.
--   - Combines pg_stat_activity, pg_locks, and pg_stat_statements.
--   - Use this as your first-response "what is happening right now" query.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    a.pid,
    now() - a.query_start                                   AS duration,
    a.state,
    COALESCE(a.wait_event_type || '/' || a.wait_event, '-') AS wait_event,
    pg_blocking_pids(a.pid)                                  AS blocking_pids,
    l.locktype                                               AS lock_type,
    l.mode                                                   AS lock_mode,
    ss.calls,
    round(ss.mean_exec_time::numeric, 2)                     AS avg_ms,
    a.usename                                                AS username,
    a.datname                                                AS dbname,
    left(a.query, 200)                                       AS query
FROM pg_stat_activity a
LEFT JOIN pg_locks l
       ON l.pid = a.pid
      AND NOT l.granted
LEFT JOIN pg_stat_statements ss
       ON ss.queryid = a.query_id
      AND ss.dbid = (SELECT oid FROM pg_database WHERE datname = a.datname)
WHERE a.state != 'idle'
  AND a.pid != pg_backend_pid()
ORDER BY duration DESC NULLS LAST, a.pid;
