-- ============================================================
-- Customer Market Analysis
-- Sample dataset: projects/customer-market-analysis/data.csv
-- Note: data.csv is a representative SAMPLE dataset (249 rows,
-- 50 customers) generated to demonstrate the analysis workflow
-- described in the portfolio project (originally run against a
-- 12,000+ row transactional dataset).
-- ============================================================

-- 1. Schema -------------------------------------------------
DROP TABLE IF EXISTS customer_transactions;

CREATE TABLE customer_transactions (
  customer_id       INT NOT NULL,
  transaction_id    INT PRIMARY KEY,
  transaction_date  DATE NOT NULL,
  product_category  VARCHAR(50) NOT NULL,
  amount            DECIMAL(10,2) NOT NULL,
  quantity          INT NOT NULL,
  region            VARCHAR(20) NOT NULL,
  age               INT NOT NULL,
  gender            VARCHAR(10) NOT NULL
);

-- Load data.csv into the table above using your database's bulk
-- loader, e.g. in MySQL:
-- LOAD DATA LOCAL INFILE 'data.csv' INTO TABLE customer_transactions
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 2. Core KPIs ------------------------------------------------
SELECT
  COUNT(DISTINCT customer_id)              AS total_customers,
  COUNT(*)                                  AS total_transactions,
  ROUND(SUM(amount), 2)                     AS total_revenue,
  ROUND(AVG(amount), 2)                     AS avg_order_value
FROM customer_transactions;

-- 3. Revenue by product category -------------------------------
SELECT
  product_category,
  COUNT(*)            AS orders,
  ROUND(SUM(amount),2) AS revenue
FROM customer_transactions
GROUP BY product_category
ORDER BY revenue DESC;

-- 4. Monthly revenue trend -------------------------------------
SELECT
  DATE_FORMAT(transaction_date, '%Y-%m') AS month,
  ROUND(SUM(amount), 2)                  AS revenue
FROM customer_transactions
GROUP BY month
ORDER BY month;

-- 5. RFM base metrics per customer ------------------------------
-- Recency: days since last purchase (relative to a fixed
-- analysis date so results are reproducible for the sample data)
WITH rfm_base AS (
  SELECT
    customer_id,
    DATEDIFF('2025-01-01', MAX(transaction_date)) AS recency_days,
    COUNT(*)                                        AS frequency,
    ROUND(SUM(amount), 2)                           AS monetary
  FROM customer_transactions
  GROUP BY customer_id
)
SELECT * FROM rfm_base
ORDER BY monetary DESC;

-- 6. Customer segmentation via RFM quartiles ---------------------
-- Splits customers into 4 segments (matches the "4 distinct
-- customer groups" described in the project summary)
WITH rfm_base AS (
  SELECT
    customer_id,
    DATEDIFF('2025-01-01', MAX(transaction_date)) AS recency_days,
    COUNT(*)                                        AS frequency,
    SUM(amount)                                     AS monetary
  FROM customer_transactions
  GROUP BY customer_id
),
scored AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    NTILE(4) OVER (ORDER BY recency_days ASC)  AS recency_score,
    NTILE(4) OVER (ORDER BY frequency DESC)    AS frequency_score,
    NTILE(4) OVER (ORDER BY monetary DESC)     AS monetary_score
  FROM rfm_base
)
SELECT
  customer_id,
  recency_days,
  frequency,
  ROUND(monetary,2) AS monetary,
  CASE
    WHEN monetary_score = 1 AND frequency_score = 1 THEN 'Champions'
    WHEN monetary_score <= 2 AND recency_score <= 2 THEN 'Loyal Customers'
    WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'At Risk'
    ELSE 'Needs Attention'
  END AS segment
FROM scored
ORDER BY monetary DESC;

-- 7. Regional performance -----------------------------------------
SELECT
  region,
  COUNT(DISTINCT customer_id) AS customers,
  ROUND(SUM(amount), 2)       AS revenue,
  ROUND(AVG(amount), 2)       AS avg_order_value
FROM customer_transactions
GROUP BY region
ORDER BY revenue DESC;
