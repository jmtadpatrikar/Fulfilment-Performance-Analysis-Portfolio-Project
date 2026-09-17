/*
Purpose
  Create a cleaned order-reviews table while preserving every source review.

Cleaning performed
  - trim identifier fields
  - convert review score from VARCHARto INT
  - convert blank or whitespace-only comments to NULL
  - convert review dates to DATETIME
*/

USE olist_portfolio;

DROP TABLE IF EXISTS clean_order_reviews;

CREATE TABLE clean_order_reviews (
    source_raw_row_id BIGINT UNSIGNED NOT NULL,
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    review_score INT UNSIGNED NOT NULL,
    review_comment_title TEXT NULL,
    review_comment_message TEXT NULL,
    review_creation_date DATETIME NOT NULL,
    review_answer_timestamp DATETIME NOT NULL,
    PRIMARY KEY (review_id, order_id),
    UNIQUE KEY uq_clean_order_reviews_source_row (source_raw_row_id)
);

INSERT INTO clean_order_reviews
SELECT
    raw_row_id,
    TRIM(review_id),
    TRIM(order_id),
    CAST(TRIM(review_score) AS UNSIGNED),
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_message), ''),
    STR_TO_DATE(
        TRIM(review_creation_date),
        '%Y-%m-%d %H:%i:%s'
    ),
    STR_TO_DATE(
        TRIM(review_answer_timestamp),
        '%Y-%m-%d %H:%i:%s'
    )
FROM raw_order_reviews;

-- Validation: the raw and clean row counts should match
SELECT
    (SELECT COUNT(*) FROM raw_order_reviews) AS raw_rows,
    (SELECT COUNT(*) FROM clean_order_reviews) AS clean_rows,
    (SELECT COUNT(*) FROM clean_order_reviews)
        - (SELECT COUNT(*) FROM raw_order_reviews) AS row_count_difference;

/*
Cleaned-data check
clean_rows and distinct_reviews should match.
review scores should remain between 1 and 5.
*/
SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT review_id, order_id) AS distinct_reviews,
    MIN(review_score) AS minimum_review_score,
    MAX(review_score) AS maximum_review_score
FROM clean_order_reviews;

-- Validation: cleaned NULL counts should match missing raw comments
SELECT
    (
        SELECT COUNT(*)
        FROM raw_order_reviews
        WHERE NULLIF(TRIM(review_comment_title), '') IS NULL
    ) AS raw_missing_titles,
    (
        SELECT COUNT(*)
        FROM clean_order_reviews
        WHERE review_comment_title IS NULL
    ) AS clean_null_titles,
    (
        SELECT COUNT(*)
        FROM raw_order_reviews
        WHERE NULLIF(TRIM(review_comment_message), '') IS NULL
    ) AS raw_missing_messages,
    (
        SELECT COUNT(*)
        FROM clean_order_reviews
        WHERE review_comment_message IS NULL
    ) AS clean_null_messages;
