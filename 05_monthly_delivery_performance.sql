/*
Purpose
- Track delivery performance by order month
- Compare on time/late delivery volumes
- Calculate on time delivery percentage by month
- Calculate average delivery time each month

Method
- core-period delivered orders are grouped by purchase month
- customer and estimated delivery dates are compared by calendar date
*/

SELECT
	DATE_FORMAT(
		order_purchase_timestamp,
		'%Y-%m') AS order_month,
	COUNT(*) AS eligible_deliveries,
	SUM(
		DATE(order_delivered_customer_date)
		<= DATE(order_estimated_delivery_date)
	) AS on_time_deliveries,
	SUM(
		DATE(order_delivered_customer_date)
		> DATE(order_estimated_delivery_date)
	) AS late_deliveries,
	ROUND(
		SUM(
			DATE(order_delivered_customer_date)
			<= DATE(order_estimated_delivery_date)
		) / COUNT(*) * 100
	, 2) AS pct_on_time,
	ROUND(
		AVG(
			DATEDIFF(
			order_delivered_customer_date,
			order_purchase_timestamp)
			)
	, 2) AS avg_delivery_days
FROM clean_orders
WHERE is_core_period = 1
AND order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

/*
Findings
- monthly on-time delivery performance shows no pattern of constant
improvement or decline across the core period
*/
