-- ============================================================
-- Script:      streaming_replication_status.sql
-- Category:    06_replication_ha
-- Description: Shows streaming replication status for all connected standbys,
--              including lag in bytes (WAL sent vs. applied) and estimated lag
--              in seconds where write_lag/flush_lag/replay_lag are available.
--              Run this on the PRIMARY server.
--
-- Usage:       psql -h <primary-host> -U <user> -d <database> \
--                -f scripts/06_replication_ha/streaming_replication_status.sql
--
-- Output Columns:
--   standby_host    - Client hostname/IP of the standby
--   application_name- Replication slot name or application name
--   state           - Replication state (streaming, catchup, backup, etc.)
--   sync_state      - Synchronous state (async, potential, sync, quorum)
--   sent_lsn        - LSN sent by primary to this standby
--   write_lsn       - LSN written to standby's WAL
--   flush_lsn       - LSN flushed to standby's disk
--   replay_lsn      - LSN applied (replayed) by standby
--   send_lag_bytes  - Bytes of WAL sent but not yet flushed on standby
--   replay_lag_bytes- Bytes of WAL not yet replayed on standby
--   write_lag_ms    - Estimated time (ms) between send and standby write
--   flush_lag_ms    - Estimated time (ms) between send and standby flush
--   replay_lag_ms   - Estimated time (ms) between send and standby replay
--
-- Dependencies:
--   - pg_stat_replication (always available on primary)
--   - Must be run on the PRIMARY server
--   - Requires pg_monitor or superuser
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - If no rows returned: no standbys are connected (or running on standby).
--   - replay_lag_bytes > 100MB warrants investigation.
--   - replay_lag_ms > 30000 (30 seconds) is a high-latency replication situation.
--   - sync_state='sync' means this standby must acknowledge before commit returns.
--   - Use replication_slot_lag.sql to check slot-based replication lag.
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

SELECT
    client_addr                                      AS standby_host,
    application_name,
    state,
    sync_state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    -- Lag in bytes at each pipeline stage
    (sent_lsn - write_lsn)   AS send_lag_bytes,
    (sent_lsn - flush_lsn)   AS flush_lag_bytes,
    (sent_lsn - replay_lsn)  AS replay_lag_bytes,
    -- Human-readable sizes
    pg_size_pretty(sent_lsn - write_lsn)   AS send_lag,
    pg_size_pretty(sent_lsn - flush_lsn)   AS flush_lag,
    pg_size_pretty(sent_lsn - replay_lsn)  AS replay_lag,
    -- Time-based lag estimates (PG 10+)
    round(extract(epoch FROM write_lag)  * 1000)::bigint AS write_lag_ms,
    round(extract(epoch FROM flush_lag)  * 1000)::bigint AS flush_lag_ms,
    round(extract(epoch FROM replay_lag) * 1000)::bigint AS replay_lag_ms,
    now() - backend_start                            AS connection_age
FROM pg_stat_replication
ORDER BY replay_lag_bytes DESC NULLS LAST;

-- Summary: total WAL generation rate (approximate)
SELECT
    'Primary WAL LSN: ' || pg_current_wal_lsn() AS primary_info
WHERE pg_is_in_recovery() = false;
