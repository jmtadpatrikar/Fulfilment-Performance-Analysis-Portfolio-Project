/* Export the complete result grid as orders.csv */

USE olist_portfolio;

SELECT
    order_key,
    customer_key,
    customer_state,
    order_status,
    order_date,
    approval_stage_flag,
    carrier_handoff_stage_flag,
    delivered_stage_flag,
    canceled_order_flag,
    unavailable_order_flag,
    delivery_eligible_flag,
    on_time_flag,
    late_flag,
    delivery_status,
    days_to_deliver,
    days_late,
    latest_review_score,
    order_item_count,
    order_product_value,
    order_freight_value
FROM tableau_orders
ORDER BY order_key;
