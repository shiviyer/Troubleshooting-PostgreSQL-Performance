-- ============================================================
-- Script:      bgwriter_checkpoint_stats.sql
-- Category:    07_io_storage
-- Description: Analyzes PostgreSQL background writer and checkpoint statistics
--              to diagnose I/O performance issues, checkpoint pressure, and
--              dirty page write patterns. The bgwriter and checkpointer are
--              the primary background I/O producers in PostgreSQL.
--
-- Usage:       psql -h <host> -U <user> -d <database> \
--                -f scripts/07_io_storage/bgwriter_checkpoint_stats.sql
--
-- Output Sections:
--   Section 1: pg_stat_bgwriter — checkpoint and background write statistics
--   Section 2: Checkpoint configuration settings
--   Section 3: Analysis and tuning recommendations
--
-- Key Metrics Explained:
--   checkpoints_timed   - Checkpoints triggered by checkpoint_timeout (GOOD)
--   checkpoints_req     - Checkpoints triggered by checkpoint_completion_target
--                         being exceeded (BAD — too much WAL, increase max_wal_size)
--   buffers_checkpoint  - Dirty pages written BY checkpoint process
--   buffers_clean       - Dirty pages written BY background writer
--   buffers_backend     - Dirty pages written BY BACKEND (WORST — means checkpoint
--                         is behind and backend had to flush directly to disk)
--   maxwritten_clean    - How often bgwriter hit bgwriter_lru_maxpages limit
--
-- Dependencies:
--   - pg_stat_bgwriter (always available)
--   - Note: In PG16+, checkpointer stats moved to pg_stat_checkpointer
--
-- Notes:
--   - READ-ONLY. Safe for production use.
--   - HIGH buffers_backend ratio (>10%): increase max_wal_size or checkpoint_timeout.
--   - HIGH checkpoints_req/total ratio (>20%): max_wal_size too small.
--   - HIGH maxwritten_clean: increase bgwriter_lru_maxpages.
--   - Reset with: SELECT pg_stat_reset_shared('bgwriter');
--
-- PG_VERSION:  15, 16, 17, 18
-- Note:        PG16+ has pg_stat_checkpointer for checkpoint stats; pg_stat_bgwriter
--              retains bgwriter-specific stats. This script handles both versions.
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================

-- Section 1: Background writer and checkpoint statistics
SELECT 'BGWRITER / CHECKPOINT STATISTICS' AS section;

SELECT
    -- Checkpoint stats
    checkpoints_timed,
    checkpoints_req,
    round(
        100.0 * checkpoints_req
        / NULLIF(checkpoints_timed + checkpoints_req, 0), 1
    )                                                AS forced_checkpoint_pct,
    checkpoint_write_time,
    checkpoint_sync_time,
    -- Buffer write breakdown
    buffers_checkpoint,
    buffers_clean,
    buffers_backend,
    round(
        100.0 * buffers_backend
        / NULLIF(buffers_checkpoint + buffers_clean + buffers_backend, 0), 1
    )                                                AS backend_write_pct,
    -- BGwriter limits
    maxwritten_clean,
    buffers_alloc,
    -- Stats age
    stats_reset,
    now() - stats_reset                              AS time_since_reset
FROM pg_stat_bgwriter;

-- Section 2: Checkpoint configuration
SELECT '---' AS section;
SELECT 'CHECKPOINT CONFIGURATION SETTINGS' AS section;

SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'checkpoint_timeout',
    'checkpoint_completion_target',
    'max_wal_size',
    'min_wal_size',
    'bgwriter_delay',
    'bgwriter_lru_maxpages',
    'bgwriter_lru_multiplier',
    'wal_buffers',
    'fsync',
    'synchronous_commit',
    'full_page_writes'
)
ORDER BY name;

-- Section 3: PG16+ checkpointer view (if available)
-- Note: This block is only executed on PG16+
DO $$
BEGIN
  IF current_setting('server_version_num')::int >= 160000 THEN
    RAISE NOTICE 'PG16+ detected. Use pg_stat_checkpointer for checkpoint-specific stats.';
  END IF;
END $$;
