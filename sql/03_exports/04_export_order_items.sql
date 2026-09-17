/* Export the complete result grid as order_items.csv */

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
FROM tableau_items
ORDER BY order_key, order_item_id;
