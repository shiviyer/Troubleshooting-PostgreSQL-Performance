SELECT (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle' AND query_start < NOW() - INTERVAL '1 minute') AS idle_queries,
       (SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '1 minute') AS active_queries,
       (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction' AND query_start < NOW() - INTERVAL '1 minute') AS idle_in_transaction_queries,
       (SELECT count(*) FROM pg_stat_activity WHERE state = 'fastpath function call' AND query_start < NOW() - INTERVAL '1 minute') AS fastpath_queries,
       (SELECT count(*) FROM pg_stat_activity WHERE state = 'disabled' AND query_start < NOW() - INTERVAL '1 minute') AS disabled_queries;
