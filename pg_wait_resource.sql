SELECT 
    pg_stat_activity.pid, 
    pg_stat_activity.query, 
    pg_stat_activity.state, 
    pg_stat_activity.wait_event_type, 
    pg_stat_activity.wait_event 
FROM 
    pg_stat_activity JOIN pg_locks 
        ON pg_stat_activity.pid = pg_locks.pid 
WHERE 
    pg_locks.locktype = 'Relation'::text AND 
    pg_locks.mode = 'AccessExclusiveLock'::text AND 
    pg_stat_activity.wait_event_type = 'Lock'::text AND 
    pg_stat_activity.wait_event = concat(pg_locks.database::text,':',pg_locks.relation::text,' ',pg_locks.page::text)
ORDER BY pg_locks.database, pg_locks.relation, pg_locks.page;
