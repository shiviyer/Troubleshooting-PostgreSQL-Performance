-- ============================================================
-- Script:      connection_summary.sql
-- Category:    05_connection_session
-- Description: Provides a comprehensive connection summary showing total
--              connections by state, user, database, and application name.
--              Also shows remaining capacity relative to max_connections.
--              Use this as the first-look connection health dashboard.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/05_connection_session/connection_summary.sql
--
-- Output Sections:
--   Section 1: Connection counts by state
--   Section 2: Connection counts by database
--   Section 3: Top connection consumers by role and application
--   Section 4: max_connections utilization summary
--
-- Dependencies:
--   - pg_stat_activity (always available)
--   - Requires pg_monitor or superuser to see all backends
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - 'idle in transaction' connections hold locks and waste memory — investigate.
--   - 'idle' connections from pgBouncer or pools are normal but monitor counts.
--   - When connection count approaches max_connections, new connections will fail.
--   - Consider using PgBouncer if connections regularly exceed 200-300 on a single server.
--   - Reserved connections: superuser_reserved_connections are excluded from user quota.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Section 1: Connection state summary
SELECT 'CONNECTION STATE SUMMARY' AS section;

SELECT
    COALESCE(state, 'walsender/autovacuum')         AS state,
    count(*)                                         AS connections,
    round(
        100.0 * count(*) / sum(count(*)) OVER (),
        1
    )                                                AS pct_of_total
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY state
ORDER BY connections DESC;

-- Section 2: Connection count by database
SELECT '---' AS section;
SELECT 'CONNECTIONS BY DATABASE' AS section;

SELECT
    datname                                          AS database,
    count(*)                                         AS total_connections,
    count(*) FILTER (WHERE state = 'active')         AS active,
    count(*) FILTER (WHERE state = 'idle')           AS idle,
    count(*) FILTER (WHERE state ILIKE '%transaction%') AS idle_in_txn
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY datname
ORDER BY total_connections DESC;

-- Section 3: Top connection consumers
SELECT '---' AS section;
SELECT 'TOP CONNECTION CONSUMERS (ROLE + APPLICATION)' AS section;

SELECT
    usename                                          AS role,
    left(application_name, 30)                       AS application,
    count(*)                                         AS connections,
    count(*) FILTER (WHERE state = 'active')         AS active
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY usename, application_name
ORDER BY connections DESC
LIMIT 20;

-- Section 4: max_connections utilization
SELECT '---' AS section;
SELECT 'MAX_CONNECTIONS UTILIZATION' AS section;

SELECT
    current_setting('max_connections')::int          AS max_connections,
    current_setting('superuser_reserved_connections')::int
                                                     AS superuser_reserved,
    count(*)                                         AS current_connections,
    current_setting('max_connections')::int
      - count(*)                                     AS connections_available,
    round(
        100.0 * count(*)
        / current_setting('max_connections')::int, 1
    )                                                AS utilization_pct
FROM pg_stat_activity
WHERE pid != pg_backend_pid();
