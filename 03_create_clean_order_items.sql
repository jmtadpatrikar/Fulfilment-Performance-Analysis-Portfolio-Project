/*
Purpose
  Create a cleaned order-items table while preserving the raw source table.

Cleaning performed
  - trim identifier fields
  - convert the item number to an integer
  - convert the shipping deadline to DATETIME
  - convert price and freight value to DECIMAL
*/

USE olist_portfolio;

DROP TABLE IF EXISTS clean_order_items;

CREATE TABLE clean_order_items (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    order_id CHAR(32) NOT NULL,
    order_item_id INT UNSIGNED NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(9, 2) NOT NULL,
    freight_value DECIMAL(9, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    UNIQUE KEY uq_clean_order_items_source_row (source_raw_row_id)
);

INSERT INTO clean_order_items
SELECT
    raw_row_id,
    TRIM(order_id),
    CAST(TRIM(order_item_id) AS UNSIGNED),
    TRIM(product_id),
    TRIM(seller_id),
    STR_TO_DATE(
        TRIM(shipping_limit_date),
        '%Y-%m-%d %H:%i:%s'
    ),
    CAST(TRIM(price) AS DECIMAL(9, 2)),
    CAST(TRIM(freight_value) AS DECIMAL(9, 2))
FROM raw_order_items;

-- Validation: raw and clean row counts should match
SELECT
    (SELECT COUNT(*) FROM raw_order_items) AS raw_rows,
    (SELECT COUNT(*) FROM clean_order_items) AS clean_rows,
    (SELECT COUNT(*) FROM clean_order_items)
        - (SELECT COUNT(*) FROM raw_order_items) AS row_count_difference;

/*
Cleaned-data check
  clean_rows and distinct_order_items should match
  The minimum price and freight values should not be negative
*/
SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT order_id, order_item_id) AS distinct_order_items,
    MIN(price) AS minimum_price,
    MIN(freight_value) AS minimum_freight_value
FROM clean_order_items;
