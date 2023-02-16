SELECT pid, 
       now() - query_start AS duration, 
       query 
FROM pg_stat_activity 
WHERE state = 'active' AND query NOT ILIKE '%pg_stat_activity%' AND now() - query_start > interval '5 minutes'
ORDER BY duration DESC;
