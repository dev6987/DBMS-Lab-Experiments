-- ============================================================
-- EXPERIMENT 7: Functional Dependencies and Normalization
-- MySQL 8.0+
-- ============================================================
-- AIM:
-- Identify functional dependencies in a denormalized Sales table,
-- normalize it from 1NF to 3NF and BCNF, and verify lossless join
-- and dependency preservation using SQL queries.
--
-- BUSINESS RULES / FUNCTIONAL DEPENDENCIES:
-- SaleID -> SaleDate, CustomerID, SalespersonID
-- CustomerID -> CustomerName, CustomerPhone
-- SalespersonID -> SalespersonName
-- ProductID -> ProductName
-- (SaleID, ProductID) -> Quantity, UnitPriceAtSale
--
-- Candidate key of the line-item Sales relation: (SaleID, ProductID).
-- The final relations have determinants that are candidate keys,
-- so they satisfy BCNF under the stated business rules.
-- ============================================================

CREATE DATABASE IF NOT EXISTS SalesNormalizationDB;
USE SalesNormalizationDB;

-- Start clean so the experiment can be rerun.
DROP TABLE IF EXISTS SalesItem;
DROP TABLE IF EXISTS SalesOrder;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Salesperson;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Sales_Denormalized;

-- 1. DENORMALIZED SALES RELATION (one row per product in an order).
-- Repeated customer, salesperson and product descriptions illustrate
-- update, insertion and deletion anomalies in a denormalized design.
CREATE TABLE Sales_Denormalized (
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    sale_date DATE NOT NULL,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20),
    salesperson_id INT NOT NULL,
    salesperson_name VARCHAR(100) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_price_at_sale DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (sale_id, product_id)
);

INSERT INTO Sales_Denormalized VALUES
(1001, 501, '2026-01-10', 101, 'Aarav Sharma', '9876500001', 11, 'Neha Verma', 'Keyboard', 2, 1200.00),
(1001, 502, '2026-01-10', 101, 'Aarav Sharma', '9876500001', 11, 'Neha Verma', 'Mouse', 1, 650.00),
(1002, 501, '2026-01-11', 102, 'Diya Singh', '9876500002', 12, 'Rohan Mehta', 'Keyboard', 1, 1200.00),
(1002, 503, '2026-01-11', 102, 'Diya Singh', '9876500002', 12, 'Rohan Mehta', 'Monitor', 1, 9500.00),
(1003, 504, '2026-01-12', 103, 'Kabir Khan', '9876500003', 11, 'Neha Verma', 'USB Drive', 3, 550.00),
(1004, 502, '2026-01-13', 101, 'Aarav Sharma', '9876500001', 12, 'Rohan Mehta', 'Mouse', 2, 650.00);

SELECT * FROM Sales_Denormalized ORDER BY sale_id, product_id;

-- 2. NORMALIZED DESIGN (1NF, then 2NF/3NF/BCNF decomposition).
-- Atomic attributes satisfy 1NF. Partial and transitive dependencies
-- are removed by separating customer, salesperson, product, order
-- header and order-item facts into their own relations.

CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20)
);

CREATE TABLE Salesperson (
    salesperson_id INT PRIMARY KEY,
    salesperson_name VARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL
);

CREATE TABLE SalesOrder (
    sale_id INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    customer_id INT NOT NULL,
    salesperson_id INT NOT NULL,
    CONSTRAINT fk_salesorder_customer
        FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT fk_salesorder_salesperson
        FOREIGN KEY (salesperson_id) REFERENCES Salesperson(salesperson_id)
);

CREATE TABLE SalesItem (
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price_at_sale DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (sale_id, product_id),
    CONSTRAINT fk_salesitem_order
        FOREIGN KEY (sale_id) REFERENCES SalesOrder(sale_id),
    CONSTRAINT fk_salesitem_product
        FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- Populate lookup tables without duplicating descriptive attributes.
INSERT INTO Customer VALUES
(101, 'Aarav Sharma', '9876500001'),
(102, 'Diya Singh', '9876500002'),
(103, 'Kabir Khan', '9876500003');

INSERT INTO Salesperson VALUES
(11, 'Neha Verma'),
(12, 'Rohan Mehta');

INSERT INTO Product VALUES
(501, 'Keyboard'),
(502, 'Mouse'),
(503, 'Monitor'),
(504, 'USB Drive');

INSERT INTO SalesOrder VALUES
(1001, '2026-01-10', 101, 11),
(1002, '2026-01-11', 102, 12),
(1003, '2026-01-12', 103, 11),
(1004, '2026-01-13', 101, 12);

INSERT INTO SalesItem VALUES
(1001, 501, 2, 1200.00),
(1001, 502, 1, 650.00),
(1002, 501, 1, 1200.00),
(1002, 503, 1, 9500.00),
(1003, 504, 3, 550.00),
(1004, 502, 2, 650.00);

-- 3. VERIFY NORMALIZED RELATIONS.
SELECT * FROM Customer;
SELECT * FROM Salesperson;
SELECT * FROM Product;
SELECT * FROM SalesOrder;
SELECT * FROM SalesItem;

-- 4. LOSSLESS-JOIN VERIFICATION.
-- Joining the decomposed relations reconstructs the original
-- line-item facts. Compare this result with Sales_Denormalized.
SELECT
    so.sale_id,
    si.product_id,
    so.sale_date,
    c.customer_id,
    c.customer_name,
    c.customer_phone,
    sp.salesperson_id,
    sp.salesperson_name,
    p.product_name,
    si.quantity,
    si.unit_price_at_sale
FROM SalesOrder so
JOIN Customer c ON so.customer_id = c.customer_id
JOIN Salesperson sp ON so.salesperson_id = sp.salesperson_id
JOIN SalesItem si ON so.sale_id = si.sale_id
JOIN Product p ON si.product_id = p.product_id
ORDER BY so.sale_id, si.product_id;

-- Compare row counts. Both should return 6.
SELECT COUNT(*) AS denormalized_rows FROM Sales_Denormalized;

SELECT COUNT(*) AS reconstructed_rows
FROM SalesOrder so
JOIN Customer c ON so.customer_id = c.customer_id
JOIN Salesperson sp ON so.salesperson_id = sp.salesperson_id
JOIN SalesItem si ON so.sale_id = si.sale_id
JOIN Product p ON si.product_id = p.product_id;

-- 5. DEPENDENCY-PRESERVATION CHECKS.
-- Each listed dependency can be checked within one decomposed table:
-- CustomerID -> CustomerName, CustomerPhone
SELECT customer_id, COUNT(*) AS rows_per_customer
FROM Customer
GROUP BY customer_id;

-- SalespersonID -> SalespersonName
SELECT salesperson_id, COUNT(*) AS rows_per_salesperson
FROM Salesperson
GROUP BY salesperson_id;

-- ProductID -> ProductName
SELECT product_id, COUNT(*) AS rows_per_product
FROM Product
GROUP BY product_id;

-- SaleID -> SaleDate, CustomerID, SalespersonID
SELECT sale_id, COUNT(*) AS rows_per_order
FROM SalesOrder
GROUP BY sale_id;

-- (SaleID, ProductID) -> Quantity, UnitPriceAtSale
SELECT sale_id, product_id, COUNT(*) AS rows_per_order_item
FROM SalesItem
GROUP BY sale_id, product_id;

-- 6. ANOMALY DEMONSTRATION.
-- Customer details are stored once in Customer, so changing a phone
-- number requires one update rather than updating every sales row.
UPDATE Customer
SET customer_phone = '9876500099'
WHERE customer_id = 101;

SELECT * FROM Customer WHERE customer_id = 101;

-- RESULT:
-- The denormalized relation was decomposed into Customer, Salesperson,
-- Product, SalesOrder and SalesItem. The joins reconstruct all six
-- original line-item rows, and the stated dependencies are represented
-- within individual relations. Under the stated FDs, the final relations
-- are in BCNF.
