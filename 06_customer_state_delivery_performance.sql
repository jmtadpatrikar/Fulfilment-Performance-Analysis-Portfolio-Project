/*
Purpose
- Compare delivery performance across customer states
- Identify states with weaker on-time performance
- Calculate average delivery time for each included state

Method
- Core-period delivered orders are joined to the customer's state
- Actual and estimated delivery dates are compared by calendar date
- States with fewer than 100 eligible deliveries are excluded to avoid
drawing conclusions from very small groups
*/

SELECT 
	c.customer_state,
	COUNT(*) AS eligible_deliveries,
	SUM(
		DATE(o.order_delivered_customer_date)
		<= DATE(o.order_estimated_delivery_date)
	) AS on_time_deliveries,
	SUM(
		DATE(o.order_delivered_customer_date)
		> DATE(o.order_estimated_delivery_date)
	) AS late_deliveries,
    ROUND(
		SUM(
			DATE(o.order_delivered_customer_date)
			<= DATE(o.order_estimated_delivery_date)
		) / COUNT(*) * 100
	, 2) AS pct_on_time,
	ROUND(
		AVG(
			DATEDIFF(
			o.order_delivered_customer_date,
			o.order_purchase_timestamp)
			)
	, 2) AS avg_delivery_days
FROM clean_orders o
JOIN clean_customers c
	ON o.customer_id = c.customer_id
WHERE o.is_core_period = 1
	AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_status = 'delivered' 
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY pct_on_time ASC;

/*
Findings
- AL recorded the lowest on-time rate at 78.54%
	- average delivery time was 24.48 days
- RJ combined high delivery volume with weaker on-time performance
	- 1,495 of 12,310 deliveries, or 12.14%, were late
- SP recorded the largest delivery volume
	- 95.50% of its 40,399 deliveries were on time
	- its high volume still resulted in 1,817 late deliveries
*/
