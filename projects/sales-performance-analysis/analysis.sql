-- ============================================================
-- Sales Performance Analysis
-- Sample dataset: projects/sales-performance-analysis/data.csv
-- Note: data.csv is a representative SAMPLE dataset (260 rows)
-- generated to demonstrate the repeatable reporting workflow
-- described in the portfolio project (originally run against a
-- 50,000-record sales dataset).
-- ============================================================

-- 1. Schema -------------------------------------------------
DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
  sale_id     INT PRIMARY KEY,
  sale_date   DATE NOT NULL,
  sales_rep   VARCHAR(100) NOT NULL,
  region      VARCHAR(20) NOT NULL,
  product     VARCHAR(50) NOT NULL,
  units_sold  INT NOT NULL,
  unit_price  DECIMAL(10,2) NOT NULL,
  revenue     DECIMAL(12,2) NOT NULL,
  channel     VARCHAR(20) NOT NULL
);

-- Load data.csv into the table above, e.g. in MySQL:
-- LOAD DATA LOCAL INFILE 'data.csv' INTO TABLE sales
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 2. Core KPIs ------------------------------------------------
SELECT
  COUNT(*)                    AS total_sales,
  ROUND(SUM(revenue), 2)      AS total_revenue,
  ROUND(AVG(revenue), 2)      AS avg_sale_value,
  COUNT(DISTINCT sales_rep)   AS active_reps
FROM sales;

-- 3. Revenue by region ------------------------------------------
SELECT
  region,
  COUNT(*)               AS orders,
  ROUND(SUM(revenue), 2) AS revenue
FROM sales
GROUP BY region
ORDER BY revenue DESC;

-- 4. Revenue by sales rep (leaderboard) ---------------------------
SELECT
  sales_rep,
  COUNT(*)               AS orders,
  ROUND(SUM(revenue), 2) AS revenue
FROM sales
GROUP BY sales_rep
ORDER BY revenue DESC;

-- 5. Monthly revenue trend -----------------------------------------
SELECT
  DATE_FORMAT(sale_date, '%Y-%m') AS month,
  ROUND(SUM(revenue), 2)          AS revenue
FROM sales
GROUP BY month
ORDER BY month;

-- 6. Top products by revenue ----------------------------------------
SELECT
  product,
  SUM(units_sold)          AS units_sold,
  ROUND(SUM(revenue), 2)   AS revenue
FROM sales
GROUP BY product
ORDER BY revenue DESC;

-- 7. Online vs. Retail channel split ----------------------------------
SELECT
  channel,
  COUNT(*)                AS orders,
  ROUND(SUM(revenue), 2)  AS revenue,
  ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM sales), 1) AS pct_of_total
FROM sales
GROUP BY channel;

-- 8. Repeatable reporting view ----------------------------------------
-- This view is what makes the reporting "repeatable": each new
-- reporting cycle just re-queries this view instead of rebuilding
-- the aggregation logic from scratch (the "40% faster reporting"
-- improvement referenced in the project summary).
CREATE OR REPLACE VIEW sales_performance_report AS
SELECT
  region,
  DATE_FORMAT(sale_date, '%Y-%m') AS month,
  COUNT(*)                        AS orders,
  ROUND(SUM(revenue), 2)          AS revenue
FROM sales
GROUP BY region, month;

SELECT * FROM sales_performance_report ORDER BY month, region;
