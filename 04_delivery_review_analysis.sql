/*
Purpose
- Select the latest submitted review for each order
- Amount of eligible deliveries receiving a review
- Average review score for on time and late deliveries
- Percent of on time/late deliveries receiving 'low review scores'
  (review score of 1/2)

Method
ROW_NUMBER and PARTITION BY assigns a ranking within each order_id
The newest review receives review_rank = 1
this allows order contributes no more than 1 review
their last review is what analysis will be based against
*/

WITH ranked_reviews AS (
SELECT
source_raw_row_id,
order_id,
review_score,
review_answer_timestamp,

    ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY
            review_answer_timestamp DESC,
            source_raw_row_id DESC
    ) AS review_rank

FROM clean_order_reviews

)
SELECT

CASE
        WHEN DATE(o.order_delivered_customer_date)
            <= DATE(o.order_estimated_delivery_date)
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_status,
COUNT(*) AS eligible_deliveries,
COUNT(r.order_id) AS reviewed_deliveries,
ROUND(
	COUNT(r.order_id)/COUNT(*) * 100,
    2) AS review_pct,
ROUND(
	AVG(r.review_score), 2) AS avg_score,
ROUND(
	SUM(r.review_score IN (1, 2))
    /NULLIF (COUNT(r.review_score), 0) * 100, 2)
    AS low_score_pct

FROM clean_orders o
LEFT JOIN ranked_reviews r
ON o.order_id = r.order_id
AND r.review_rank = 1
WHERE o.is_core_period = 1
AND o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

/*
Finding
- late delivery is strongly associated with customer satisfaction
- late delivery average review score = 2.27
- on time delivery average review score = 4.29
- 62.42% of late deliveries received a low score (1/2)
- 9.25% of on time deliveries received a low score (1/2)
*/
