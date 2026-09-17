/* Export the complete result grid as data/processed/order_items.csv. */

USE olist_portfolio;

SELECT
    order_key,
    order_item_id,
    product_category,
    seller_key,
    seller_label,
    seller_state,
    item_price,
    freight_value
FROM powerbi_order_items
ORDER BY order_key, order_item_id;
