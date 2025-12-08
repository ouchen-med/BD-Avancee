SELECT state, COUNT(*)
FROM pg_stat_activity
GROUP BY state;


-------------------

SELECT pid,
usename,
state,
LEFT(query, 50) AS query,
query_start
FROM pg_stat_activity
WHERE datname = 'pagila';


--Check Database Size:


-- Size of current database
SELECT pg_size_pretty(pg_database_size('pagila')) AS database_size;
-- Size of all databases
SELECT datname,
pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

--3.4 Check Table Sizes:


SELECT relname AS table_name,
pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
pg_size_pretty(pg_relation_size(relid)) AS data_size,
pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;



--- Cache Hit Ratio:

SELECT
sum(heap_blks_hit) AS cache_hits,
sum(heap_blks_read) AS disk_reads,
CASE
WHEN sum(heap_blks_hit) + sum(heap_blks_read) > 0
THEN round(sum(heap_blks_hit) * 100.0 /
(sum(heap_blks_hit) + sum(heap_blks_read)), 2)
ELSE 0
END AS hit_percentage
FROM pg_statio_user_tables;


-- Find Long-Running Queries:


SELECT pid,
usename,
now() - query_start AS duration,
LEFT(query, 60) AS query
FROM pg_stat_activity
WHERE state = 'active'
AND now() - query_start > interval '1 minute'
ORDER BY duration DESC;


---If you find a problem query, you can cancel it:
-- Gentle cancel (query only)
SELECT pg_cancel_backend(12345); -- Replace with actual PID
-- Force terminate (entire connection)
SELECT pg_terminate_backend(12345); -- Use with caution!


--3.7 Health Check Query (All-in-One):

SELECT 'Connections' AS metric,
COUNT(*)::text AS value
FROM pg_stat_activity
WHERE datname = 'pagila'
UNION ALL
SELECT 'Database Size',
pg_size_pretty(pg_database_size('pagila'))
UNION ALL
SELECT 'Dead Rows (Total)',
SUM(n_dead_tup)::text
FROM pg_stat_user_tables
UNION ALL
SELECT 'Cache Hit %',
COALESCE(
round(sum(heap_blks_hit) * 100.0 /
NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 1)::text,
'N/A'
)
FROM pg_statio_user_tables;


-----------------------
--                   --
--         fi Exercise 4: Routine Maintenance          --:
--PostgreSQL uses MVCC (Multi-Version Concurrency Control). When you UPDATE or
--DELETE rows, old versions stay on disk as dead tuples. Too many = bloat = slower
--queries.
--4.1 Check Dead Tuples
--see which tables have dead rows:


SELECT relname AS table_name,
n_live_tup AS live_rows,
n_dead_tup AS dead_rows,
last_autovacuum,
last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 10;


--4.2 Simulate Bloat
--Let’s create some dead tuples to see how maintenance works:
-- Create dead tuples by updating rows
UPDATE rental
SET return_date = return_date
WHERE rental_id < 5000;
--Now check dead tuples again:
SELECT relname, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'rental';


--You should see ~5000 dead rows.


--3-4Run VACUUM ANALYZE:
-- VACUUM removes dead tuples
-- ANALYZE updates statistics for query planner

VACUUM ANALYZE rental;


---Verify cleanup:

SELECT relname, n_live_tup, n_dead_tup, last_vacuum
FROM pg_stat_user_tables
WHERE relname = 'rental';