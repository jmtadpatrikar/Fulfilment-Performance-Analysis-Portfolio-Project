/*
Purpose
  Measure how core-period orders progress through the observable fulfilment
  stages: purchase, approval, carrier hand-off, and customer delivery.

Rate definitions
  - approval rate: approved orders / purchased orders
  - carrier hand-off rate: handed-off approved orders / approved orders
  - delivery rate: customer delivered orders / handed-off orders
  - cancellation and unavailable rates: status count / purchased orders
*/

SELECT
    COUNT(*) AS purchased_orders,
    SUM(order_approved_at IS NOT NULL) AS approved_orders,
    SUM(order_approved_at IS NOT NULL
        AND order_delivered_carrier_date IS NOT NULL ) 
	AS carrier_handoff_orders,
    SUM(order_approved_at IS NOT NULL
        AND order_delivered_carrier_date IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
    ) AS delivered_orders,
    ROUND(100 * SUM(order_approved_at IS NOT NULL)/ COUNT(*), 2
    ) AS approval_rate_pct,
    ROUND(100 * SUM(order_approved_at IS NOT NULL
            AND order_delivered_carrier_date IS NOT NULL
        )
        / NULLIF(SUM(order_approved_at IS NOT NULL), 0), 2
    ) AS carrier_handoff_rate_pct,
    ROUND(100 * SUM(order_approved_at IS NOT NULL
            AND order_delivered_carrier_date IS NOT NULL
            AND order_delivered_customer_date IS NOT NULL
        )
        / NULLIF(SUM(order_approved_at IS NOT NULL
            AND order_delivered_carrier_date IS NOT NULL), 0), 2
    ) AS delivery_rate_pct,
    SUM(order_status = 'canceled') AS canceled_orders,
    ROUND(
        100 * SUM(order_status = 'canceled') / COUNT(*), 2
    ) AS cancellation_rate_pct,
    SUM(order_status = 'unavailable') AS unavailable_orders,
    ROUND(
        100 * SUM(order_status = 'unavailable') / COUNT(*), 2
    ) AS unavailable_rate_pct
FROM clean_orders
WHERE is_core_period = 1;

/*
Findings
- 99,092 total orders
- 99.86% of which reached approval
- 98.39% of approved orders were handed off to carriers
- 98.8% of handed off orders reached customers
- The largest funnel reduction occurred between approval and carrier hand-off.
- Cancellation and unavailable rates were both below 1%.
*/
