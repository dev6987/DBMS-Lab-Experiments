-- ============================================================
-- EXPERIMENT 9: Railway Booking – 5,000 Rows and Index Benchmark
-- MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS RailwayDB;
USE RailwayDB;

DROP TABLE IF EXISTS railway_booking;

CREATE TABLE railway_booking (
    booking_id BIGINT PRIMARY KEY,
    train_no INT NOT NULL,
    journey_date DATE NOT NULL,
    passenger_id INT NOT NULL,
    from_station VARCHAR(50) NOT NULL,
    to_station VARCHAR(50) NOT NULL,
    seat_no VARCHAR(10) NOT NULL,
    fare DECIMAL(8,2) NOT NULL,
    booking_status VARCHAR(20) NOT NULL
) ENGINE = InnoDB;

-- Generate exactly 5,000 rows using 10 x 10 x 10 x 5 combinations.
INSERT INTO railway_booking
(booking_id, train_no, journey_date, passenger_id,
 from_station, to_station, seat_no, fare, booking_status)
SELECT
    n AS booking_id,
    12000 + MOD(n, 25) AS train_no,
    DATE_ADD('2026-01-01', INTERVAL MOD(n, 180) DAY) AS journey_date,
    50000 + n AS passenger_id,
    CASE MOD(n, 4)
        WHEN 0 THEN 'Lucknow'
        WHEN 1 THEN 'Delhi'
        WHEN 2 THEN 'Kanpur'
        ELSE 'Varanasi'
    END AS from_station,
    CASE MOD(n, 4)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Jaipur'
        WHEN 2 THEN 'Prayagraj'
        ELSE 'Mumbai'
    END AS to_station,
    CONCAT('S', LPAD(MOD(n, 72) + 1, 2, '0')) AS seat_no,
    300 + MOD(n * 7, 1700) AS fare,
    CASE
        WHEN MOD(n, 10) = 0 THEN 'CANCELLED'
        WHEN MOD(n, 5) = 0 THEN 'WAITLIST'
        ELSE 'CONFIRMED'
    END AS booking_status
FROM (
    SELECT
        1
        + d0.d
        + 10 * d1.d
        + 100 * d2.d
        + 1000 * d3.d AS n
    FROM
        (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
    CROSS JOIN
        (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
        (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN
        (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) d3
) numbers;

-- Verify the required record count: should be 5000.
SELECT COUNT(*) AS total_bookings FROM railway_booking;

-- 1. BENCHMARK BEFORE INDEXING.
-- Run EXPLAIN and execute the query before creating secondary indexes.
EXPLAIN
SELECT booking_id, journey_date, passenger_id, booking_status
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31';

SELECT booking_id, journey_date, passenger_id, booking_status
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31';

-- 2. SINGLE-COLUMN INDEX.
CREATE INDEX idx_railway_train_no
ON railway_booking(train_no);

EXPLAIN
SELECT booking_id, journey_date, passenger_id, booking_status
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31';

-- 3. COMPOSITE INDEX for train number and journey date.
CREATE INDEX idx_railway_train_date
ON railway_booking(train_no, journey_date);

EXPLAIN
SELECT booking_id, journey_date, passenger_id, booking_status
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31';

-- 4. A second query that can use the composite index.
EXPLAIN
SELECT COUNT(*) AS confirmed_bookings
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31'
  AND booking_status = 'CONFIRMED';

SELECT COUNT(*) AS confirmed_bookings
FROM railway_booking
WHERE train_no = 12005
  AND journey_date BETWEEN '2026-02-01' AND '2026-03-31'
  AND booking_status = 'CONFIRMED';

-- 5. Inspect indexes and table statistics.
SHOW INDEX FROM railway_booking;
ANALYZE TABLE railway_booking;

-- Compare EXPLAIN output before and after indexing:
-- access type, possible_keys, key, rows and Extra.
-- Use the SQL client's timing display to record elapsed times.
