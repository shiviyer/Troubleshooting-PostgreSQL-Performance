SELECT
  pid,
  query,
  state,
  total_time,
  cpu_time,
  rows,
  calls,
  blk_read_time,
  blk_write_time,
  shared_blks_hit,
  shared_blks_read,
  shared_blks_dirtied,
  shared_blks_written,
  local_blks_hit,
  local_blks_read,
  local_blks_dirtied,
  local_blks_written,
  temp_blks_read,
  temp_blks_written,
  temp_files,
  pg_stat_activity.wait_event_type,
  pg_stat_activity.wait_event,
  pg_locks.mode AS lock_mode,
  pg_locks.granted,
  pg_index.indisname AS index_name,
  pg_index.indisunique AS index_is_unique,
  pg_stat_activity.query_start,
  pg_stat_activity.state_change,
  pg_stat_activity.backend_xid,
  pg_stat_activity.backend_xmin
FROM pg_stat_activity
LEFT JOIN pg_locks ON pg_locks.pid = pg_stat_activity.pid
LEFT JOIN pg_index ON pg_index.indexrelid = pg_stat_activity.current_query
WHERE pg_stat_activity.state != 'idle'
ORDER BY total_time DESC;
