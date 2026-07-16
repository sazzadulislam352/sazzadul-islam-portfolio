-- ============================================================
-- Automated Employee Reporting System
-- Sample dataset: projects/automated-employee-reporting/data.csv
-- Note: data.csv is a representative SAMPLE dataset (200 rows,
-- 50 employees x 4 months) generated to demonstrate the automated
-- reporting workflow described in the portfolio project
-- (originally run against 10,000+ rows of employee data).
-- ============================================================

-- 1. Schema -------------------------------------------------
DROP TABLE IF EXISTS employee_performance;

CREATE TABLE employee_performance (
  employee_id       INT NOT NULL,
  employee_name     VARCHAR(100) NOT NULL,
  department        VARCHAR(50) NOT NULL,
  month             CHAR(7) NOT NULL,   -- format YYYY-MM
  sales_target      INT NOT NULL,
  sales_achieved    INT NOT NULL,
  attendance_rate   DECIMAL(5,2) NOT NULL,
  performance_score DECIMAL(5,2) NOT NULL,
  review_rating     INT NOT NULL,
  PRIMARY KEY (employee_id, month)
);

-- Load data.csv into the table above, e.g. in MySQL:
-- LOAD DATA LOCAL INFILE 'data.csv' INTO TABLE employee_performance
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 2. Core KPIs ------------------------------------------------
SELECT
  COUNT(DISTINCT employee_id)               AS total_employees,
  ROUND(AVG(performance_score), 2)          AS avg_performance_score,
  ROUND(AVG(attendance_rate), 2)            AS avg_attendance_rate,
  ROUND(AVG(sales_achieved/sales_target)*100, 1) AS avg_target_attainment_pct
FROM employee_performance;

-- 3. Average performance by department ---------------------------
SELECT
  department,
  COUNT(DISTINCT employee_id)      AS employees,
  ROUND(AVG(performance_score), 2) AS avg_performance_score,
  ROUND(AVG(review_rating), 2)     AS avg_review_rating
FROM employee_performance
GROUP BY department
ORDER BY avg_performance_score DESC;

-- 4. Monthly performance trend -------------------------------------
SELECT
  month,
  ROUND(AVG(performance_score), 2) AS avg_performance_score,
  ROUND(SUM(sales_achieved), 0)    AS total_sales_achieved
FROM employee_performance
GROUP BY month
ORDER BY month;

-- 5. Top 10 performers (latest month) --------------------------------
SELECT
  employee_id,
  employee_name,
  department,
  performance_score,
  review_rating
FROM employee_performance
WHERE month = (SELECT MAX(month) FROM employee_performance)
ORDER BY performance_score DESC
LIMIT 10;

-- 6. Employees needing attention (bottom performers, latest month) -----
SELECT
  employee_id,
  employee_name,
  department,
  performance_score,
  attendance_rate
FROM employee_performance
WHERE month = (SELECT MAX(month) FROM employee_performance)
ORDER BY performance_score ASC
LIMIT 10;

-- 7. Automated reporting view --------------------------------------
-- Recreating this as a view is what "automates" the recurring
-- report: any BI tool or script can just SELECT * FROM this view
-- each month instead of re-writing the aggregation logic.
CREATE OR REPLACE VIEW monthly_performance_report AS
SELECT
  department,
  month,
  COUNT(DISTINCT employee_id)       AS employees,
  ROUND(AVG(performance_score), 2)  AS avg_performance_score,
  ROUND(AVG(attendance_rate), 2)    AS avg_attendance_rate,
  ROUND(SUM(sales_achieved), 0)     AS total_sales_achieved,
  ROUND(SUM(sales_target), 0)       AS total_sales_target
FROM employee_performance
GROUP BY department, month;

SELECT * FROM monthly_performance_report ORDER BY month, department;
