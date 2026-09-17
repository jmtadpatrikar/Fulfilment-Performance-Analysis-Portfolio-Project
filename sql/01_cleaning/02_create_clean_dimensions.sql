/*
Purpose
  Create cleaned customer, product, and seller tables while preserving
  the raw source tables
  
  - handle misspelled column names
*/

USE olist_portfolio;

-- Customers

DROP TABLE IF EXISTS clean_customers;

CREATE TABLE clean_customers (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    customer_id CHAR(32) NOT NULL,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix CHAR(5) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2) NOT NULL,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_clean_customers_source_row (source_raw_row_id)
);

INSERT INTO clean_customers
SELECT
    raw_row_id,
    TRIM(customer_id),
    TRIM(customer_unique_id),
    TRIM(customer_zip_code_prefix),
    LOWER(TRIM(customer_city)),
    UPPER(TRIM(customer_state))
FROM raw_customers;

-- Products

DROP TABLE IF EXISTS clean_products;

CREATE TABLE clean_products (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    product_id CHAR(32) NOT NULL,
    product_category_name_portuguese VARCHAR(100) NULL,
    product_category_label VARCHAR(100) NOT NULL,
    product_name_length INT UNSIGNED NULL,
    product_description_length INT UNSIGNED NULL,
    product_photos_qty INT UNSIGNED NULL,
    product_weight_g INT UNSIGNED NULL,
    product_length_cm INT UNSIGNED NULL,
    product_height_cm INT UNSIGNED NULL,
    product_width_cm INT UNSIGNED NULL,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_clean_products_source_row (source_raw_row_id)
);

INSERT INTO clean_products
SELECT
    p.raw_row_id,
    TRIM(p.product_id),
    NULLIF(TRIM(p.product_category_name), ''),
    COALESCE
	(
        NULLIF(TRIM(t.product_category_name_english), ''),
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown / unclassified'
    ),
    CAST(NULLIF(TRIM(p.product_name_lenght), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_description_lenght), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_photos_qty), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_weight_g), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_length_cm), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_height_cm), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(p.product_width_cm), '') AS UNSIGNED)
FROM raw_products p
LEFT JOIN raw_category_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name);

-- Sellers

DROP TABLE IF EXISTS clean_sellers;

CREATE TABLE clean_sellers (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    seller_id CHAR(32) NOT NULL,
    seller_zip_code_prefix CHAR(5) NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state CHAR(2) NOT NULL,
    PRIMARY KEY (seller_id),
    UNIQUE KEY uq_clean_sellers_source_row (source_raw_row_id)
);

INSERT INTO clean_sellers
SELECT
    raw_row_id,
    TRIM(seller_id),
    TRIM(seller_zip_code_prefix),
    LOWER(TRIM(seller_city)),
    UPPER(TRIM(seller_state))
FROM raw_sellers;



-- Validation: raw and clean row counts should match
SELECT
    'customers' AS table_name,
    (SELECT COUNT(*) FROM raw_customers) AS raw_rows,
    (SELECT COUNT(*) FROM clean_customers) AS clean_rows
UNION 
SELECT
    'products',
    (SELECT COUNT(*) FROM raw_products),
    (SELECT COUNT(*) FROM clean_products)
UNION
SELECT
    'sellers',
    (SELECT COUNT(*) FROM raw_sellers),
    (SELECT COUNT(*) FROM clean_sellers);

/*
Category validation
	Unknown categories should match in both raw
    and cleaned tables
*/

SELECT
    (
        SELECT COUNT(*)
        FROM raw_products
        WHERE NULLIF(TRIM(product_category_name), '') IS NULL
    ) AS raw_missing_categories,
    (
        SELECT COUNT(*)
        FROM clean_products
        WHERE product_category_label = 'Unknown / unclassified'
    ) AS clean_unknown_categories;
