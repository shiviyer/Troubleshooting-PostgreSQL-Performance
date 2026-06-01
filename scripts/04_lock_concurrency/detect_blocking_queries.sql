-- ============================================================
-- Script:      detect_blocking_queries.sql
-- Category:    04_lock_concurrency
-- Description: Detects all blocking and waiting query pairs currently active
--              in the database. Shows which query is blocked, which query is
--              blocking it, lock types, and duration. The most important
--              first-response query during a locking incident.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/04_lock_concurrency/detect_blocking_queries.sql
--
-- Output Columns:
--   waiting_pid     - PID of the blocked (waiting) session
--   blocking_pid    - PID of the session causing the block
--   wait_duration   - How long the blocked session has been waiting
--   locktype        - Type of lock being contested (relation, tuple, transactionid)
--   lock_mode       - Lock mode being requested by the waiting session
--   waiting_query   - Query text of the blocked session
--   blocking_query  - Query text of the blocking session
--   blocking_state  - State of the blocking session
--   waiting_user    - User running the blocked query
--   blocking_user   - User running the blocking query
--
-- Dependencies:
--   - pg_stat_activity (always available)
--   - pg_locks (always available)
--   - Requires pg_monitor or superuser to see other sessions
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - Run this immediately when users report slow queries or timeouts.
--   - Use pg_blocking_pids() for simpler single-level blocking detection.
--   - For the full blocking chain, use lock_tree_hierarchy.sql.
--   - blocking_state='idle in transaction': application opened transaction and forgot to commit.
--   - To resolve: pg_cancel_backend(<blocking_pid>) or pg_terminate_backend(<blocking_pid>)
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    waiting.pid                                      AS waiting_pid,
    blocking.pid                                     AS blocking_pid,
    now() - waiting.query_start                      AS wait_duration,
    w_lock.locktype,
    w_lock.mode                                      AS lock_mode,
    COALESCE(
        waiting.wait_event_type || '/' || waiting.wait_event,
        '-'
    )                                                AS wait_event,
    left(waiting.query, 150)                         AS waiting_query,
    left(blocking.query, 150)                        AS blocking_query,
    blocking.state                                   AS blocking_state,
    waiting.usename                                  AS waiting_user,
    blocking.usename                                 AS blocking_user,
    waiting.datname                                  AS database
FROM pg_stat_activity     AS waiting
JOIN pg_locks             AS w_lock  ON w_lock.pid = waiting.pid
                                    AND NOT w_lock.granted
JOIN pg_locks             AS b_lock  ON b_lock.pid != waiting.pid
                                    AND b_lock.granted
                                    AND b_lock.locktype    = w_lock.locktype
                                    AND b_lock.database   IS NOT DISTINCT FROM w_lock.database
                                    AND b_lock.relation   IS NOT DISTINCT FROM w_lock.relation
                                    AND b_lock.page       IS NOT DISTINCT FROM w_lock.page
                                    AND b_lock.tuple      IS NOT DISTINCT FROM w_lock.tuple
                                    AND b_lock.virtualxid IS NOT DISTINCT FROM w_lock.virtualxid
                                    AND b_lock.transactionid IS NOT DISTINCT FROM w_lock.transactionid
                                    AND b_lock.classid    IS NOT DISTINCT FROM w_lock.classid
                                    AND b_lock.objid      IS NOT DISTINCT FROM w_lock.objid
                                    AND b_lock.objsubid   IS NOT DISTINCT FROM w_lock.objsubid
JOIN pg_stat_activity     AS blocking ON blocking.pid = b_lock.pid
WHERE waiting.pid != pg_backend_pid()
ORDER BY wait_duration DESC NULLS LAST;
