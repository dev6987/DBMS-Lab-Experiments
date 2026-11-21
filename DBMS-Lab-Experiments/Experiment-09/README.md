# Experiment 9 – Railway Booking Index Benchmark

**Aim:** Create a Railway Booking table with at least 5,000 records and compare query plans before and after single-column and composite indexes.

## What the script does
- Creates `RailwayDB.railway_booking`.
- Generates exactly 5,000 deterministic sample rows.
- Runs a filter query and `EXPLAIN` before indexing.
- Creates a single-column index on `train_no`.
- Creates a composite index on `(train_no, journey_date)`.
- Repeats `EXPLAIN`, runs a filtered aggregate, and displays index metadata.

## Run and record results
1. Run `experiment-09.sql` in MySQL 8.0+.
2. Note the `EXPLAIN` columns `type`, `possible_keys`, `key`, `rows` and `Extra` before and after indexes.
3. Record execution time shown by your SQL client for the same SELECT before and after indexing.
4. Do not assume an index must be selected for every query; optimizer choices depend on selectivity, table size and statistics.

The SQL script does not invent benchmark timings. Record the actual values from your own MySQL run.
