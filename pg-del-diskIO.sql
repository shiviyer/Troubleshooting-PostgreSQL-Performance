WITH sample_data AS (
  SELECT now() AS sample_time,
         sum(blk_read_time) AS total_read_time,
         sum(blk_write_time) AS total_write_time,
         sum(blks_read) AS total_blocks_read,
         sum(blks_hit) AS total_blocks_hit,
         sum(tup_returned) AS total_tuples_returned,
         sum(tup_fetched) AS total_tuples_fetched,
         sum(tup_deleted) AS total_tuples_deleted
  FROM pg_stat_database
), 
diff_data AS (
  SELECT a.*, 
         extract(epoch from b.sample_time - a.sample_time) AS diff_time,
         b.total_read_time AS prev_read_time,
         b.total_write_time AS prev_write_time,
         b.total_blocks_read AS prev_blocks_read,
         b.total_blocks_hit AS prev_blocks_hit,
         b.total_tuples_returned AS prev_tuples_returned,
         b.total_tuples_fetched AS prev_tuples_fetched,
         b.total_tuples_deleted AS prev_tuples_deleted
  FROM sample_data a
  LEFT JOIN sample_data b ON b.sample_time < a.sample_time
), 
final_data AS (
  SELECT max(total_read_time) AS max_read_time,
         max(total_write_time) AS max_write_time,
         max(total_blocks_read) AS max_blocks_read,
         max(total_blocks_hit) AS max_blocks_hit,
         max(total_tuples_returned) AS max_tuples_returned,
         max(total_tuples_fetched) AS max_tuples_fetched,
         max(total_tuples_deleted) AS max_tuples_deleted,
         sum(diff_time) AS total_time,
         sum(diff_time * total_read_time) / sum(diff_time) AS slope_read_time,
         sum(diff_time * total_write_time) / sum(diff_time) AS slope_write_time,
         sum(diff_time * total_blocks_read) / sum(diff_time) AS slope_blocks_read,
         sum(diff_time * total_blocks_hit) / sum(diff_time) AS slope_blocks_hit,
         sum(diff_time * total_tuples_returned) / sum(diff_time) AS slope_tuples_returned,
         sum(diff_time * total_tuples_fetched) / sum(diff_time) AS slope_tuples_fetched,
         sum(diff_time * total_tuples_deleted) / sum(diff_time) AS slope_tuples_deleted
  FROM diff_data
), 
forecast_data AS (
  SELECT max_read_time,
         max_write_time,
         max_blocks_read,
         max_blocks_hit,
         max_tuples_returned,
         max_tuples_fetched,
         max_tuples_deleted,
         total_time,
         slope_read_time,
         slope_write_time,
         slope_blocks_read,
         slope_blocks_hit,
         slope_tuples_returned,
         slope_tuples_fetched,
         slope_tuples_deleted,
         (max_read_time + slope_read_time * total_time) AS forecast_read_time,
         (max_write_time + slope_write_time * total_time) AS forecast_write_time,
         (max_blocks_read + slope_blocks_read * total_time) AS forecast_blocks_read,
         (max_blocks_hit + slope_blocks_hit * total_time) AS forecast_blocks_hit,
         (max_tuples_returned + slope_tuples_returned * total_time) AS forecast_tuples_returned,
         (max_tuples_fetched + slope_tuples_fetched * total_time) AS forecast_tuples_fetched,
         (max_tuples_deleted + slope_tuples_deleted * total_time) AS forecast_tuples_deleted
  FROM final_data
)
SELECT *
FROM forecast_data;
