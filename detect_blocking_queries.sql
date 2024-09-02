--This title reflects the purpose of the PostgreSQL query, which is to detect and display blocking and waiting queries currently running in the database.

SELECT waiting.pid    AS waiting_pid,
       waiting.query  AS waiting_query,
       blocking.pid   AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_stat_activity AS waiting
         JOIN pg_locks AS w_lock ON waiting.pid = w_lock.pid
         JOIN pg_locks AS b_lock ON w_lock.locktype = b_lock.locktype AND w_lock.database = b_lock.database AND
                                    w_lock.relation = b_lock.relation AND w_lock.page = b_lock.page AND
                                    w_lock.tuple = b_lock.tuple AND w_lock.virtualxid = b_lock.virtualxid AND
                                    w_lock.transactionid = b_lock.transactionid AND w_lock.classid = b_lock.classid AND
                                    w_lock.objid = b_lock.objid AND w_lock.objsubid = b_lock.objsubid AND
                                    w_lock.pid != b_lock.pid
         JOIN pg_stat_activity AS blocking ON blocking.pid = b_lock.pid
WHERE w_lock.granted
  AND NOT b_lock.granted;
