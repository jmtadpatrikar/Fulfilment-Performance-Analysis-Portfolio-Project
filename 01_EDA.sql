/*
Purpose
  Perform EDA on the cleaned tables before calculating the main business KPIs.
*/

USE olist_portfolio;

-- 1. How many rows are in each cleaned table?
SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM clean_orders
UNION
SELECT 'customers', COUNT(*)
FROM clean_customers
UNION
SELECT 'products', COUNT(*)
FROM clean_products
UNION
SELECT 'sellers', COUNT(*)
FROM clean_sellers
UNION
SELECT 'order_items', COUNT(*)
FROM clean_order_items
UNION
SELECT 'order_payments', COUNT(*)
FROM clean_order_payments
UNION
SELECT 'order_reviews', COUNT(*)
FROM clean_order_reviews;

-- 2. What period does the order data cover?
SELECT
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase,
    SUM(is_core_period = 1) AS core_period_orders,
    SUM(is_core_period = 0) AS boundary_period_orders
FROM clean_orders;

-- 3. What order statuses appear in the core period?
SELECT
    order_status,
    COUNT(*) AS orders
FROM clean_orders
WHERE is_core_period = 1
GROUP BY order_status
ORDER BY orders DESC;

-- 4. Which payment types appear most often?
	-- These counts represent payment components, not distinct orders.
SELECT
    payment_type,
    COUNT(*) AS payment_components
FROM clean_order_payments
GROUP BY payment_type
ORDER BY payment_components DESC;


-- 5. How are review scores distributed?
	-- These counts represent review records 
    -- Selecting one latest review per order will happen in a later analysis
SELECT
    review_score,
    COUNT(*) AS review_records
FROM clean_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6. Which months had the highest orders in the core period?
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS orders
FROM clean_orders
WHERE is_core_period = 1
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY orders DESC;

/*
Findings
- the dataset contains 99,092 orders within the core period
- 97% of all orders have been delivered
- credit card is the most common payment method (73.92%)
- November 2017 saw the highest volume of orders
Credit card is the most common payment component, representing 73.92% of
payment records. Five-star reviews are the most common review score.
*/
