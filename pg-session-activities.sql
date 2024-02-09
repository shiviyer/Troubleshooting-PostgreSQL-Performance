SELECT pid,
       now() - pg_stat_activity.query_start AS duration,
       query,
       usename,
       client_addr,
       application_name,
       state,
       wait_event_type,
       wait_event,
       pg_stat_get_backend_pid(pid) AS client_pid
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start DESC;
