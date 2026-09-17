/*
Purpose
  Measure delivery speed and on-time performance for completed orders in the
  core analysis period.

Method
  The CTE calculates delivery days, days late, and on-time status for each
  eligible delivery. The final query summarises the counts, rate, and averages.
*/

WITH eligible_deliveries AS (
    SELECT
        order_id,
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        ) AS days_to_deliver,
        GREATEST(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            ), 0
				) AS days_late,
        CASE
            WHEN DATE(order_delivered_customer_date)
                <= DATE(order_estimated_delivery_date)
            THEN 'On time'
            ELSE 'Late'
        END AS delivery_status
    FROM clean_orders
    WHERE order_status = 'delivered'
      AND is_core_period = 1
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    COUNT(*) AS total_deliveries,
    SUM(delivery_status = 'On time') AS on_time_deliveries,
    SUM(delivery_status = 'Late') AS late_deliveries,
    ROUND(
        (SUM(delivery_status = 'On time') / COUNT(*)) * 100, 2
		) AS on_time_pct,
    ROUND(AVG(days_to_deliver), 2) AS avg_delivery_days,
    ROUND(
        AVG(
            CASE
                WHEN delivery_status = 'Late' THEN days_late
            END), 2
		) AS late_order_avg_days
FROM eligible_deliveries;

/*
Findings
- 96,203 total delivered orders
- 93.21% of delivered orders were on time
- average delivery time of 12 days
- late deliveries arrived on average 10 days after estimated
*/
