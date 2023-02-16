SELECT a.pid, 
       a.client_addr, 
       a.application_name, 
       a.query, 
       now() - a.query_start AS duration, 
       l.relation::regclass, 
       l.mode
FROM pg_stat_activity a 
LEFT JOIN pg_locks l 
ON l.pid = a.pid 
WHERE a.state = 'active'
ORDER BY duration DESC;
