-- ============================================================
-- EXPERIMENT 10: Query Optimization with 10,000+ Rows
-- MySQL 8.0.18+ recommended for EXPLAIN ANALYZE.
-- ============================================================

CREATE DATABASE IF NOT EXISTS QueryOptimizationDB;
USE QueryOptimizationDB;

DROP TABLE IF EXISTS sales_analytics;

CREATE TABLE sales_analytics (
    record_id BIGINT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    region VARCHAR(20) NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    sales_rep_id INT NOT NULL
) ENGINE = InnoDB;

-- Generate exactly 10,000 rows using four 10-value digit sets.
INSERT INTO sales_analytics
(record_id, customer_id, product_id, region, sale_date,
 quantity, unit_price, status, sales_rep_id)
SELECT
    n AS record_id,
    1000 + MOD(n, 500) AS customer_id,
    200 + MOD(n, 80) AS product_id,
    CASE MOD(n, 4)
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        ELSE 'West'
    END AS region,
    DATE_ADD('2024-01-01', INTERVAL MOD(n, 730) DAY) AS sale_date,
    1 + MOD(n, 8) AS quantity,
    100 + MOD(n * 13, 1900) AS unit_price,
    CASE
        WHEN MOD(n, 9) = 0 THEN 'RETURNED'
        WHEN MOD(n, 5) = 0 THEN 'PENDING'
        ELSE 'COMPLETED'
    END AS status,
    1 + MOD(n, 40) AS sales_rep_id
FROM (
    SELECT
        1 + d0.d + 10*d1.d + 100*d2.d + 1000*d3.d AS n
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
        (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
) numbers;

SELECT COUNT(*) AS total_records FROM sales_analytics;

-- ============================================================
-- PART A: FIVE SLOW / LESS OPTIMIZED QUERY EXAMPLES
-- Run EXPLAIN before each query. If supported, run EXPLAIN ANALYZE
-- to see actual execution details. Record client execution time.
-- ============================================================

-- SLOW QUERY 1: applying YEAR() to the date column can prevent
-- efficient range access through a normal index on sale_date.
EXPLAIN
SELECT COUNT(*) AS sales_in_2025
FROM sales_analytics
WHERE YEAR(sale_date) = 2025;

SELECT COUNT(*) AS sales_in_2025
FROM sales_analytics
WHERE YEAR(sale_date) = 2025;

-- SLOW QUERY 2: leading wildcard search generally cannot use a
-- normal B-tree index efficiently.
EXPLAIN
SELECT record_id, customer_id, region
FROM sales_analytics
WHERE region LIKE '%th';

SELECT record_id, customer_id, region
FROM sales_analytics
WHERE region LIKE '%th';

-- SLOW QUERY 3: correlated aggregate subquery runs logically
-- for each outer row (optimizer may transform it).
EXPLAIN
SELECT s.record_id, s.customer_id, s.unit_price
FROM sales_analytics s
WHERE s.unit_price > (
    SELECT AVG(s2.unit_price)
    FROM sales_analytics s2
    WHERE s2.region = s.region
);

SELECT s.record_id, s.customer_id, s.unit_price
FROM sales_analytics s
WHERE s.unit_price > (
    SELECT AVG(s2.unit_price)
    FROM sales_analytics s2
    WHERE s2.region = s.region
);

-- SLOW QUERY 4: OR across separate columns can complicate index use.
EXPLAIN
SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE customer_id = 1100 OR product_id = 225;

SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE customer_id = 1100 OR product_id = 225;

-- SLOW QUERY 5: non-sargable expression on quantity.
EXPLAIN
SELECT SUM(quantity * unit_price) AS revenue
FROM sales_analytics
WHERE quantity + 1 > 5;

SELECT SUM(quantity * unit_price) AS revenue
FROM sales_analytics
WHERE quantity + 1 > 5;

-- ============================================================
-- PART B: CREATE INDEXES AND REWRITE QUERIES
-- ============================================================

CREATE INDEX idx_sales_date ON sales_analytics(sale_date);
CREATE INDEX idx_sales_region ON sales_analytics(region);
CREATE INDEX idx_sales_region_price ON sales_analytics(region, unit_price);
CREATE INDEX idx_sales_customer ON sales_analytics(customer_id);
CREATE INDEX idx_sales_product ON sales_analytics(product_id);
CREATE INDEX idx_sales_quantity ON sales_analytics(quantity);

ANALYZE TABLE sales_analytics;

-- OPTIMIZED QUERY 1: use a date range rather than YEAR(sale_date).
EXPLAIN
SELECT COUNT(*) AS sales_in_2025
FROM sales_analytics
WHERE sale_date >= '2025-01-01'
  AND sale_date < '2026-01-01';

SELECT COUNT(*) AS sales_in_2025
FROM sales_analytics
WHERE sale_date >= '2025-01-01'
  AND sale_date < '2026-01-01';

-- OPTIMIZED QUERY 2: a leading-wildcard LIKE cannot be made
-- equivalent to a prefix search without changing its meaning.
-- For this small fixed set of regions, use explicit equality values
-- matching the intended suffix condition: North and South.
EXPLAIN
SELECT record_id, customer_id, region
FROM sales_analytics
WHERE region IN ('North', 'South');

SELECT record_id, customer_id, region
FROM sales_analytics
WHERE region IN ('North', 'South');

-- OPTIMIZED QUERY 3: pre-aggregate average price by region and JOIN.
EXPLAIN
SELECT s.record_id, s.customer_id, s.unit_price
FROM sales_analytics s
JOIN (
    SELECT region, AVG(unit_price) AS average_region_price
    FROM sales_analytics
    GROUP BY region
) a ON a.region = s.region
WHERE s.unit_price > a.average_region_price;

SELECT s.record_id, s.customer_id, s.unit_price
FROM sales_analytics s
JOIN (
    SELECT region, AVG(unit_price) AS average_region_price
    FROM sales_analytics
    GROUP BY region
) a ON a.region = s.region
WHERE s.unit_price > a.average_region_price;

-- OPTIMIZED QUERY 4: UNION removes duplicates and allows each
-- equality predicate to use its own index.
EXPLAIN
SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE customer_id = 1100
UNION
SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE product_id = 225;

SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE customer_id = 1100
UNION
SELECT record_id, customer_id, product_id, status
FROM sales_analytics
WHERE product_id = 225;

-- OPTIMIZED QUERY 5: move arithmetic to the constant side.
EXPLAIN
SELECT SUM(quantity * unit_price) AS revenue
FROM sales_analytics
WHERE quantity > 4;

SELECT SUM(quantity * unit_price) AS revenue
FROM sales_analytics
WHERE quantity > 4;

-- ============================================================
-- PART C: OPTIONAL ACTUAL EXECUTION PLANS
-- Requires MySQL 8.0.18+. Run individually if supported.
-- ============================================================
-- EXPLAIN ANALYZE
-- SELECT COUNT(*) FROM sales_analytics
-- WHERE sale_date >= '2025-01-01' AND sale_date < '2026-01-01';
--
-- EXPLAIN ANALYZE
-- SELECT SUM(quantity * unit_price)
-- FROM sales_analytics
-- WHERE quantity > 4;

-- Show created indexes.
SHOW INDEX FROM sales_analytics;

-- Final row-count check.
SELECT COUNT(*) AS total_records FROM sales_analytics;

-- IMPORTANT:
-- Capture actual execution times from your MySQL client before and
-- after optimization. EXPLAIN ANALYZE reports actual timing on
-- supported versions. Do not write assumed timing values in your
-- practical record.
