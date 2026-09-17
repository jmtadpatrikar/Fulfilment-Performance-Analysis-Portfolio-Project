/*
Purpose
create the three tables  for the Power BI desktop report

Exports
	- powerbi_dates: one row per calendar date in the core period
	- powerbi_orders: one row per core-period order
	- powerbi_order_items: one row per core-period order item
*/

USE olist_portfolio;

DROP TABLE IF EXISTS powerbi_order_items;
DROP TABLE IF EXISTS powerbi_orders;
DROP TABLE IF EXISTS powerbi_dates;

CREATE TABLE powerbi_dates (
    calendar_date DATE NOT NULL,
    calendar_year SMALLINT UNSIGNED NOT NULL,
    month_number TINYINT UNSIGNED NOT NULL,
    month_name VARCHAR(9) NOT NULL,
    month_start DATE NOT NULL,
    PRIMARY KEY (calendar_date)
);

INSERT INTO powerbi_dates (
    calendar_date,
    calendar_year,
    month_number,
    month_name,
    month_start
)
WITH RECURSIVE calendar AS (
    SELECT DATE('2017-01-01') AS calendar_date
    UNION ALL
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM calendar
    WHERE calendar_date < '2018-08-31'
)
SELECT
    calendar_date,
    YEAR(calendar_date),
    MONTH(calendar_date),
    MONTHNAME(calendar_date),
    DATE_SUB(
        calendar_date,
        INTERVAL (DAYOFMONTH(calendar_date) - 1) DAY
    )
FROM calendar;

CREATE TABLE powerbi_orders (
    order_key BIGINT UNSIGNED NOT NULL,
    customer_key BIGINT UNSIGNED NOT NULL,
    customer_state CHAR(2) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    approval_stage_flag TINYINT UNSIGNED NOT NULL,
    carrier_handoff_stage_flag TINYINT UNSIGNED NOT NULL,
    delivered_stage_flag TINYINT UNSIGNED NOT NULL,
    canceled_order_flag TINYINT UNSIGNED NOT NULL,
    unavailable_order_flag TINYINT UNSIGNED NOT NULL,
    delivery_eligible_flag TINYINT UNSIGNED NOT NULL,
    on_time_flag TINYINT UNSIGNED NOT NULL,
    late_flag TINYINT UNSIGNED NOT NULL,
    delivery_status VARCHAR(12) NOT NULL,
    days_to_deliver INT NULL,
    days_late INT NULL,
    latest_review_score TINYINT UNSIGNED NULL,
    order_item_count INT UNSIGNED NOT NULL,
    order_product_value DECIMAL(12, 2) NOT NULL,
    order_freight_value DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (order_key),
    KEY idx_powerbi_orders_date (order_date),
    KEY idx_powerbi_orders_customer (customer_key),
    KEY idx_powerbi_orders_state (customer_state)
);

INSERT INTO powerbi_orders (
    order_key,
    customer_key,
    customer_state,
    order_status,
    order_date,
    approval_stage_flag,
    carrier_handoff_stage_flag,
    delivered_stage_flag,
    canceled_order_flag,
    unavailable_order_flag,
    delivery_eligible_flag,
    on_time_flag,
    late_flag,
    delivery_status,
    days_to_deliver,
    days_late,
    latest_review_score,
    order_item_count,
    order_product_value,
    order_freight_value
)
WITH
core_orders AS (
    SELECT
        o.*,
        ROW_NUMBER() OVER (ORDER BY o.order_id) AS order_key
    FROM clean_orders o
    WHERE o.is_core_period = 1
),
customer_keys AS (
    SELECT
        customer_unique_id,
        ROW_NUMBER() OVER (ORDER BY customer_unique_id) AS customer_key
    FROM (
        SELECT DISTINCT customer_unique_id
        FROM clean_customers
    ) customers
),
ranked_reviews AS (
    SELECT
        source_raw_row_id,
        order_id,
        review_score,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp DESC, source_raw_row_id DESC
        ) AS review_rank
    FROM clean_order_reviews
),
order_item_totals AS (
    SELECT
        order_id,
        COUNT(*) AS order_item_count,
        SUM(price) AS order_product_value,
        SUM(freight_value) AS order_freight_value
    FROM clean_order_items
    GROUP BY order_id
)
SELECT
    o.order_key,
    ck.customer_key,
    c.customer_state,
    o.order_status,
    DATE(o.order_purchase_timestamp),
    CASE WHEN o.order_approved_at IS NOT NULL THEN 1 ELSE 0 END,
    CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
        THEN 1 ELSE 0
    END,
    CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0
    END,
    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END,
    CASE WHEN o.order_status = 'unavailable' THEN 1 ELSE 0 END,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN 1 ELSE 0
    END,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND DATE(o.order_delivered_customer_date)
             <= DATE(o.order_estimated_delivery_date)
        THEN 1 ELSE 0
    END,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND DATE(o.order_delivered_customer_date)
             > DATE(o.order_estimated_delivery_date)
        THEN 1 ELSE 0
    END,
    CASE
        WHEN o.order_status <> 'delivered'
          OR o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN 'Not eligible'
        WHEN DATE(o.order_delivered_customer_date)
            <= DATE(o.order_estimated_delivery_date)
        THEN 'On time'
        ELSE 'Late'
    END,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        )
    END,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN GREATEST(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
            ),
            0
        )
    END,
    r.review_score,
    COALESCE(t.order_item_count, 0),
    COALESCE(t.order_product_value, 0),
    COALESCE(t.order_freight_value, 0)
FROM core_orders o
JOIN clean_customers c
  ON o.customer_id = c.customer_id
JOIN customer_keys ck
  ON c.customer_unique_id = ck.customer_unique_id
LEFT JOIN ranked_reviews r
  ON o.order_id = r.order_id
 AND r.review_rank = 1
LEFT JOIN order_item_totals t
  ON o.order_id = t.order_id;

CREATE TABLE powerbi_order_items (
    order_key BIGINT UNSIGNED NOT NULL,
    order_item_id INT UNSIGNED NOT NULL,
    product_category VARCHAR(100) NOT NULL,
    seller_key BIGINT UNSIGNED NOT NULL,
    seller_label VARCHAR(30) NOT NULL,
    seller_state CHAR(2) NOT NULL,
    item_price DECIMAL(9, 2) NOT NULL,
    freight_value DECIMAL(9, 2) NOT NULL,
    PRIMARY KEY (order_key, order_item_id),
    KEY idx_powerbi_items_category (product_category),
    KEY idx_powerbi_items_seller (seller_key)
);

INSERT INTO powerbi_order_items (
    order_key,
    order_item_id,
    product_category,
    seller_key,
    seller_label,
    seller_state,
    item_price,
    freight_value
)
WITH
core_order_keys AS (
    SELECT
        order_id,
        ROW_NUMBER() OVER (ORDER BY order_id) AS order_key
    FROM clean_orders
    WHERE is_core_period = 1
),
used_sellers AS (
    SELECT DISTINCT i.seller_id
    FROM clean_order_items i
    JOIN clean_orders o
      ON i.order_id = o.order_id
    WHERE o.is_core_period = 1
),
seller_keys AS (
    SELECT
        seller_id,
        ROW_NUMBER() OVER (ORDER BY seller_id) AS seller_key
    FROM used_sellers
)
SELECT
    o.order_key,
    i.order_item_id,
    p.product_category_label,
    k.seller_key,
    CONCAT('Seller ', LPAD(k.seller_key, 4, '0')),
    s.seller_state,
    i.price,
    i.freight_value
FROM clean_order_items i
JOIN core_order_keys o
  ON i.order_id = o.order_id
JOIN clean_products p
  ON i.product_id = p.product_id
JOIN seller_keys k
  ON i.seller_id = k.seller_id
JOIN clean_sellers s
  ON i.seller_id = s.seller_id;
