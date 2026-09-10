-- mart_product_performance.sql
-- Product sales performance with margin and category ranking
-- Sources: stg_products + stg_orders + RAW ecommerce.order_items

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

order_items AS (
    SELECT * FROM {{ source('ecommerce', 'order_items') }}
),

orders AS (
    SELECT order_id FROM {{ ref('stg_orders') }}
),

item_sales AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity)        AS units_sold,
        SUM(oi.line_total)      AS total_revenue,
        AVG(oi.unit_price)      AS avg_selling_price
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
),

ranked AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        p.category,
        COALESCE(s.units_sold, 0)           AS units_sold,
        COALESCE(s.total_revenue, 0)        AS total_revenue,
        COALESCE(s.avg_selling_price, p.price) AS avg_selling_price,
        p.margin_pct,
        ROW_NUMBER() OVER (
            PARTITION BY p.category
            ORDER BY COALESCE(s.total_revenue, 0) DESC
        )                                   AS rank_in_category,
        p.is_active,
        CURRENT_TIMESTAMP()                 AS _dbt_run_at
    FROM products p
    LEFT JOIN item_sales s ON p.product_id = s.product_id
)

SELECT * FROM ranked
