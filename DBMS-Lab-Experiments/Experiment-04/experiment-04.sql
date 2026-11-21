-- ============================================================
-- EXPERIMENT 4: Joins, Subqueries, Set Operations and EXPLAIN
-- Requires Experiment 3 to have been executed.
-- ============================================================
USE CompanyDB;

-- 1. INNER JOIN: employees and their departments.
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-- 2. LEFT JOIN: show every department, including departments
-- that might not have any employees.
SELECT
    d.dept_id,
    d.dept_name,
    e.emp_name,
    e.salary
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id
ORDER BY d.dept_id, e.emp_id;

-- 3. SELF-JOIN: compare pairs of employees in the same department.
-- e1.emp_id < e2.emp_id avoids duplicate/reversed pairs.
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    e1.dept_id,
    e1.salary AS salary_1,
    e2.salary AS salary_2
FROM Employee e1
INNER JOIN Employee e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id
ORDER BY e1.dept_id, e1.emp_id, e2.emp_id
LIMIT 10;

-- 4. THREE-WAY JOIN: employee, department and project.
SELECT
    e.emp_name,
    d.dept_name,
    p.project_name,
    e.salary
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
INNER JOIN Project p ON e.project_id = p.project_id
ORDER BY d.dept_name, e.emp_name;

-- 5. CORRELATED SUBQUERY: employees earning more than
-- the average salary in their own department.
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    e.dept_id
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
)
ORDER BY e.dept_id, e.salary DESC;

-- 6. EXISTS: departments having at least one employee
-- earning more than 80,000.
SELECT
    d.dept_id,
    d.dept_name
FROM Department d
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.dept_id = d.dept_id
      AND e.salary > 80000
)
ORDER BY d.dept_id;

-- 7. SIMULATED INTERSECT: employees who are in IT
-- AND earn more than 70,000.
SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id IN (
    SELECT emp_id
    FROM Employee
    WHERE dept_id = 1
)
AND emp_id IN (
    SELECT emp_id
    FROM Employee
    WHERE salary > 70000
)
ORDER BY emp_id;

-- 8. SIMULATED EXCEPT: employees earning more than 70,000
-- EXCEPT those belonging to IT.
SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id IN (
    SELECT emp_id
    FROM Employee
    WHERE salary > 70000
)
AND emp_id NOT IN (
    SELECT emp_id
    FROM Employee
    WHERE dept_id = 1
)
ORDER BY emp_id;

-- 9A. EXPLAIN for INNER JOIN.
EXPLAIN
SELECT e.emp_name, d.dept_name
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
WHERE e.salary > 70000;

-- 9B. EXPLAIN for correlated subquery.
EXPLAIN
SELECT e.emp_name, e.salary
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
);

-- 9C. EXPLAIN for EXISTS.
EXPLAIN
SELECT d.dept_name
FROM Department d
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.dept_id = d.dept_id
      AND e.salary > 80000
);

-- Compare the actual EXPLAIN output for join access, subquery
-- processing and existence filtering. Plans depend on MySQL version,
-- indexes, table size and optimizer decisions.
