SELECT
  date,
  SUM(cpu_usage) as y,
  toEpochSecond(date) as x
FROM system.metrics
WHERE metric LIKE 'cpu.%'
GROUP BY date
ORDER BY date ASC
INTO OUTFILE '/tmp/cpu_usage.csv';

\set x_label 'Time'
\set y_label 'CPU Usage (%)'

\set x_column 3
\set y_column 2

\set degree 1

SELECT
  (SELECT MAX(date) FROM system.metrics) + INTERVAL '1 day' as date,
  :y_label as y_label,
  LINEAR_REG(:x_column, :y_column, degree) OVER () as regression
FROM system.metrics
LIMIT 1;
