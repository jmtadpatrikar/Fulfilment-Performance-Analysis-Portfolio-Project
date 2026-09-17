/*
Purpose
  Create a cleaned order-payments table while preserving every payment
  component from the raw source table.

Cleaning performed
  - trim identifier and payment-type fields
  - standardise payment type to lowercase
  - convert payment sequence and instalments from VARCHAR to INT
  - convert payment value from VARCHAR to DECIMAL
*/

USE olist_portfolio;

DROP TABLE IF EXISTS clean_order_payments;

CREATE TABLE clean_order_payments (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    order_id CHAR(32) NOT NULL,
    payment_sequential INT UNSIGNED NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    payment_installments INT UNSIGNED NOT NULL,
    payment_value DECIMAL(9, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    UNIQUE KEY uq_clean_order_payments_source_row (source_raw_row_id)
);

INSERT INTO clean_order_payments
SELECT
    raw_row_id,
    TRIM(order_id),
    CAST(TRIM(payment_sequential) AS UNSIGNED),
    LOWER(TRIM(payment_type)),
    CAST(TRIM(payment_installments) AS UNSIGNED),
    CAST(TRIM(payment_value) AS DECIMAL(9, 2))
FROM raw_order_payments;

-- Validation: the raw and clean row counts should match
SELECT
    (SELECT COUNT(*) FROM raw_order_payments) AS raw_rows,
    (SELECT COUNT(*) FROM clean_order_payments) AS clean_rows,
    (SELECT COUNT(*) FROM clean_order_payments)
        - (SELECT COUNT(*) FROM raw_order_payments) AS row_count_difference;

/*
Cleaned-data check
clean_rows and distinct_payment_components should match
The minimum payment value should not be negative.
*/
SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT order_id, payment_sequential)
        AS distinct_payment_components,
    MIN(payment_value) AS minimum_payment_value
FROM clean_order_payments;
