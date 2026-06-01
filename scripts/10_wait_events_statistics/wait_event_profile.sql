-- ============================================================
-- Script:      wait_event_profile.sql
-- Category:    10_wait_events_statistics
-- Description: Builds a real-time wait event profile by sampling pg_stat_activity
--              multiple times over a short interval. This approximates the
--              "Active Session History" (ASH) methodology used in Oracle AWR.
--              Shows what ALL active backends are waiting on right now.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/10_wait_events_statistics/wait_event_profile.sql
--
-- Output Columns (Section 1 - Current Snapshot):
--   wait_event_type  - Category of wait event (Lock, LWLock, IO, CPU, etc.)
--   wait_event       - Specific wait event name
--   backends         - Number of backends in this wait state right now
--   pct_of_active    - Percentage of active backends in this state
--   sample_queries   - Sample query texts (aggregated, truncated)
--
-- Output Columns (Section 2 - Active Backends with no wait):
--   pid              - Backend PID
--   duration_ms      - Query duration in milliseconds
--   query            - Query text (first 100 chars)
--
-- Dependencies:
--   - pg_stat_activity (always available)
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - Run this repeatedly during performance issues to identify bottlenecks.
--   - CPU: backends running on CPU (no explicit wait) — may indicate CPU saturation.
--   - Lock: explicit row/table locks; use lock_tree_hierarchy.sql to investigate.
--   - LWLock: internal lightweight locks — may indicate contention on system structures.
--   - IO: backends waiting for I/O — disk bottleneck or sequential scan overuse.
--   - For a more sophisticated ASH implementation, consider pg_wait_sampling extension.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Section 1: Wait event profile (current moment)
SELECT 'CURRENT WAIT EVENT PROFILE' AS section;

SELECT
    COALESCE(wait_event_type, 'CPU (no wait)')       AS wait_event_type,
    COALESCE(wait_event,      '-')                   AS wait_event,
    count(*)                                         AS backends,
    round(
        100.0 * count(*)
        / sum(count(*)) OVER (), 1
    )                                                AS pct_of_active,
    string_agg(
        DISTINCT left(query, 60),
        ' | '
        ORDER BY left(query, 60)
    )                                                AS sample_queries
FROM pg_stat_activity
WHERE state = 'active'
  AND pid != pg_backend_pid()
GROUP BY wait_event_type, wait_event
ORDER BY backends DESC;

-- Section 2: Backends using CPU (no wait event = actively running)
SELECT '---' AS section;
SELECT 'ACTIVE BACKENDS ON CPU (CURRENTLY EXECUTING)' AS section;

SELECT
    pid,
    now() - query_start                             AS duration,
    round(
        extract(epoch FROM (now() - query_start)) * 1000
    )::bigint                                        AS duration_ms,
    usename                                          AS username,
    datname                                          AS database,
    left(query, 100)                                 AS query
FROM pg_stat_activity
WHERE state = 'active'
  AND wait_event IS NULL
  AND wait_event_type IS NULL
  AND pid != pg_backend_pid()
ORDER BY duration DESC;

-- Section 3: Summary of all backends by state
SELECT '---' AS section;
SELECT 'ALL BACKENDS BY STATE' AS section;

SELECT
    COALESCE(state, 'walsender')                     AS state,
    count(*)                                         AS count
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY state
ORDER BY count DESC;
