-- stg_orders.sql
-- Source: RAW_DB.ecommerce.orders + order_items (loaded by ADF from MySQL)
-- Target: STAGING_DB.retail.stg_orders

WITH orders AS (
    SELECT * FROM {{ source('ecommerce', 'orders') }}
),

items_agg AS (
    SELECT
        order_id,
        COUNT(*)            AS item_count,
        SUM(line_total)     AS items_subtotal,
        SUM(quantity)       AS total_qty
    FROM {{ source('ecommerce', 'order_items') }}
    GROUP BY order_id
),

joined AS (
    SELECT
        o.id                                    AS order_id,
        o.customer_id,
        CAST(o.order_date AS DATE)              AS order_date,
        o.status,
        COALESCE(ia.item_count, 0)              AS item_count,
        COALESCE(ia.total_qty, 0)               AS total_qty,
        COALESCE(ia.items_subtotal, 0)          AS subtotal,
        o.total_amount,
        o.currency,
        o.created_at,
        CURRENT_TIMESTAMP()                     AS _dbt_loaded_at,
        'ecommerce.orders'                      AS _source
    FROM orders o
    LEFT JOIN items_agg ia ON o.id = ia.order_id
    WHERE o.status != 'cancelled'
)

SELECT * FROM joined
