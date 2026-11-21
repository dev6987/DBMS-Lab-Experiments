-- ============================================================
-- EXPERIMENT 5: Views, View Updatability and Recursive CTE
-- Requires Experiment 3. Run this script once on the base schema.
-- MySQL 8.0+ is required for WITH RECURSIVE.
-- ============================================================
USE CompanyDB;

-- Add manager_id to Employee for the reporting hierarchy.
-- Execute this ALTER only once; if the column already exists,
-- do not execute it again.
ALTER TABLE Employee
    ADD COLUMN manager_id INT NULL;

ALTER TABLE Employee
    ADD CONSTRAINT fk_employee_manager
    FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

-- Assign department heads and reporting chains.
-- Each department head has no manager (NULL).
UPDATE Employee SET manager_id = NULL WHERE emp_id IN (1, 7, 13, 19, 25);

UPDATE Employee SET manager_id = 1 WHERE emp_id = 2;
UPDATE Employee SET manager_id = 2 WHERE emp_id = 3;
UPDATE Employee SET manager_id = 3 WHERE emp_id = 4;
UPDATE Employee SET manager_id = 4 WHERE emp_id = 5;
UPDATE Employee SET manager_id = 5 WHERE emp_id = 6;

UPDATE Employee SET manager_id = 7 WHERE emp_id = 8;
UPDATE Employee SET manager_id = 8 WHERE emp_id = 9;
UPDATE Employee SET manager_id = 9 WHERE emp_id = 10;
UPDATE Employee SET manager_id = 10 WHERE emp_id = 11;
UPDATE Employee SET manager_id = 11 WHERE emp_id = 12;

UPDATE Employee SET manager_id = 13 WHERE emp_id = 14;
UPDATE Employee SET manager_id = 14 WHERE emp_id = 15;
UPDATE Employee SET manager_id = 15 WHERE emp_id = 16;
UPDATE Employee SET manager_id = 16 WHERE emp_id = 17;
UPDATE Employee SET manager_id = 17 WHERE emp_id = 18;

UPDATE Employee SET manager_id = 19 WHERE emp_id = 20;
UPDATE Employee SET manager_id = 20 WHERE emp_id = 21;
UPDATE Employee SET manager_id = 21 WHERE emp_id = 22;
UPDATE Employee SET manager_id = 22 WHERE emp_id = 23;
UPDATE Employee SET manager_id = 23 WHERE emp_id = 24;

UPDATE Employee SET manager_id = 25 WHERE emp_id = 26;
UPDATE Employee SET manager_id = 26 WHERE emp_id = 27;
UPDATE Employee SET manager_id = 27 WHERE emp_id = 28;
UPDATE Employee SET manager_id = 28 WHERE emp_id = 29;
UPDATE Employee SET manager_id = 29 WHERE emp_id = 30;

-- 1. DEPARTMENT SALARY SUMMARY VIEW.
CREATE OR REPLACE VIEW department_salary_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS average_salary,
    MIN(e.salary) AS minimum_salary,
    MAX(e.salary) AS maximum_salary,
    SUM(e.salary) AS total_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM department_salary_summary ORDER BY dept_id;

-- 2. EMPLOYEE HIERARCHY VIEW: employee and immediate manager.
CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT
    e.emp_id,
    e.emp_name,
    e.dept_id,
    d.dept_name,
    e.manager_id,
    m.emp_name AS manager_name,
    e.salary
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
LEFT JOIN Employee m ON e.manager_id = m.emp_id;

SELECT * FROM employee_hierarchy ORDER BY emp_id;

-- 3. VIEW UPDATABILITY TEST.
-- The grouped/aggregate department_salary_summary view is not
-- directly updatable in MySQL because it uses GROUP BY and aggregates.
-- Uncomment and run separately to observe the expected error:
-- UPDATE department_salary_summary
-- SET average_salary = average_salary + 1000
-- WHERE dept_id = 1;

-- A join view's updatability depends on the view definition and
-- which base-table column is changed. Do not assume every joined
-- view is automatically non-updatable.
-- Example optional test (changes the underlying Employee salary):
-- UPDATE employee_hierarchy
-- SET salary = salary + 1000
-- WHERE emp_id = 6;
-- SELECT emp_id, emp_name, salary FROM Employee WHERE emp_id = 6;

-- 4. RECURSIVE CTE: display reporting chains from department heads.
WITH RECURSIVE reporting_chain AS (
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        1 AS reporting_level,
        CAST(e.emp_name AS CHAR(1000)) AS reporting_path
    FROM Employee e
    WHERE e.manager_id IS NULL

    UNION ALL

    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        rc.reporting_level + 1,
        CONCAT(rc.reporting_path, ' -> ', e.emp_name)
    FROM Employee e
    INNER JOIN reporting_chain rc
        ON e.manager_id = rc.emp_id
)
SELECT
    emp_id,
    emp_name,
    manager_id,
    reporting_level,
    reporting_path
FROM reporting_chain
ORDER BY reporting_path;
