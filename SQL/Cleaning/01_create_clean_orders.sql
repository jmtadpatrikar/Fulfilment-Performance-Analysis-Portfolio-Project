/*
Purpose
  Build clean order table without changing raw_orders.

Cleaning rules
  - Trim IDs and status
  - Standardise status to lowercase.
  - Convert timestamp strings imported as VARCHAR to DATETIME.
  - Mark the core period used for comparable trend analysis.
  - Keep the sparse boundary periods rather than deleting them.
*/

USE olist_portfolio;

DROP TABLE IF EXISTS clean_orders;

CREATE TABLE clean_orders (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,
    is_core_period TINYINT NOT NULL,
    dq_delivered_missing_approval TINYINT NOT NULL,
    dq_delivered_missing_carrier TINYINT NOT NULL,
    dq_delivered_missing_delivery TINYINT NOT NULL,
    PRIMARY KEY (order_id),
    UNIQUE KEY uq_clean_orders_source_row (source_raw_row_id)
);

INSERT INTO clean_orders (
    source_raw_row_id,
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    is_core_period,
    dq_delivered_missing_approval,
    dq_delivered_missing_carrier,
    dq_delivered_missing_delivery
)
SELECT
    raw_row_id,
    TRIM(order_id),
    TRIM(customer_id),
    LOWER(TRIM(order_status)),
    STR_TO_DATE(TRIM(order_purchase_timestamp), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(
        NULLIF(TRIM(order_delivered_carrier_date), ''),
        '%Y-%m-%d %H:%i:%s'
    ),
    STR_TO_DATE(
        NULLIF(TRIM(order_delivered_customer_date), ''),
        '%Y-%m-%d %H:%i:%s'
    ),
    STR_TO_DATE(
        TRIM(order_estimated_delivery_date),
        '%Y-%m-%d %H:%i:%s'
    ),
    CASE
        WHEN order_purchase_timestamp >= '2017-01-01'
         AND order_purchase_timestamp < '2018-09-01'
        THEN 1 ELSE 0
    END,
    CASE
        WHEN LOWER(TRIM(order_status)) = 'delivered'
         AND TRIM(order_approved_at) = ''
        THEN 1 ELSE 0
    END,
    CASE
        WHEN LOWER(TRIM(order_status)) = 'delivered'
         AND TRIM(order_delivered_carrier_date) = ''
        THEN 1 ELSE 0
    END,
    CASE
        WHEN LOWER(TRIM(order_status)) = 'delivered'
         AND TRIM(order_delivered_customer_date) = ''
        THEN 1 ELSE 0
    END
FROM raw_orders;

-- validation: one clean row must remain for every raw order
SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    SUM(order_approved_at IS NULL) AS missing_approval,
    SUM(order_delivered_carrier_date IS NULL) AS missing_carrier_handoff,
    SUM(order_delivered_customer_date IS NULL) AS missing_delivery,
    SUM(dq_delivered_missing_approval) AS delivered_missing_approval,
    SUM(dq_delivered_missing_carrier) AS delivered_missing_carrier,
    SUM(dq_delivered_missing_delivery) AS delivered_missing_delivery
FROM clean_orders;


-- Validation: compare the two table counts independently
SELECT
    (SELECT COUNT(*) FROM raw_orders) AS raw_rows,
    (SELECT COUNT(*) FROM clean_orders) AS clean_rows,
    (SELECT COUNT(*) FROM clean_orders)
        - (SELECT COUNT(*) FROM raw_orders) AS row_count_difference;

-- confirm no missing rows
SELECT 
	r.order_id
FROM raw_orders r
LEFT JOIN clean_orders c
    USING (order_id)
WHERE c.order_id IS NULL;

-- Demonstrate the order counts in both 'core' and 'non-core periods'
SELECT
    is_core_period,
    COUNT(*) AS order_count,
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase
FROM clean_orders
GROUP BY is_core_period
ORDER BY is_core_period DESC;
