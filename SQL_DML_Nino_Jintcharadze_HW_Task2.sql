--1
CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)

--2
SELECT *, pg_size_pretty(total_bytes) AS total,
								pg_size_pretty(index_bytes) AS INDEX,
								pg_size_pretty(toast_bytes) AS toast,
								pg_size_pretty(table_bytes) AS TABLE
		   FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
						   FROM (SELECT c.oid,nspname AS table_schema,
														   relname AS TABLE_NAME,
														  c.reltuples AS row_estimate,
														  pg_total_relation_size(c.oid) AS total_bytes,
														  pg_indexes_size(c.oid) AS index_bytes,
														  pg_total_relation_size(reltoastrelid) AS toast_bytes
										  FROM pg_class c
										  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
										  WHERE relkind = 'r'
										  ) a
								) a
		   WHERE table_name LIKE '%table_to_delete%';
		   
--total_bytes = 602472448
--table_bytes = 602464256
--table = 575MB

--3
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

--a. DELETE 3333333. It took 29 secs 705 msec.
--b. total_bytes 602611712
--   table_bytes 602603520
--   total_size = 575MB
--c. 

VACUUM FULL VERBOSE table_to_delete;
--d. total_bytes = 401580032
--   table_bytes = 401571840
--   total_size = 383 MB
-- after vacuum free up some amout of storage and found 1946541 removable row

--e. 
DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)

--4. 
 TRUNCATE table_to_delete;
 --a. it took 638 msec.
 --b. tables size now is 0MB, took litteraly no time, it is way faster than DELETE operator.
 --c. DELETE operator is useful for selectively removing rows, but leave behind overhead , that is whre VACUUM come in handy
 --it is necessary opperator after DELETE, to clean up unecessary space. When data is no longer neded It will come in handy TRUNCATE


