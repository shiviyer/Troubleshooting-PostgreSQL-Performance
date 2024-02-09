SELECT datname, usename, wait_event_type, wait_event, state, 
    (EXTRACT(EPOCH FROM current_timestamp - query_start) * 1000)::bigint AS duration_ms 
FROM pg_stat_activity 
WHERE wait_event_type IS NOT NULL 
ORDER BY duration_ms DESC 
LIMIT 10;
