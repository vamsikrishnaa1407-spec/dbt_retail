-- mart_customer_ltv.sql
-- Customer lifetime value with order history
-- Sources: stg_customers + stg_orders

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

order_summary AS (
    SELECT
        customer_id,
        MIN(order_date)             AS first_order_date,
        MAX(order_date)             AS last_order_date,
        COUNT(DISTINCT order_id)    AS total_orders,
        SUM(total_amount)           AS total_spend,
        AVG(total_amount)           AS avg_order_value
    FROM orders
    GROUP BY customer_id
),

ltv AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        c.region,
        c.loyalty_tier,
        c.acquisition_channel,
        c.customer_since,
        c.is_active,
        COALESCE(os.first_order_date, c.customer_since)     AS first_order_date,
        os.last_order_date,
        COALESCE(os.total_orders, 0)                        AS total_orders,
        COALESCE(os.total_spend, c.lifetime_value)          AS total_spend,
        COALESCE(os.avg_order_value, 0)                     AS avg_order_value,
        CASE
            WHEN COALESCE(os.total_spend, c.lifetime_value) > 2000 THEN 'HIGH'
            WHEN COALESCE(os.total_spend, c.lifetime_value) > 500  THEN 'MED'
            ELSE 'LOW'
        END                                                 AS ltv_segment,
        CURRENT_TIMESTAMP()                                 AS _dbt_run_at
    FROM customers c
    LEFT JOIN order_summary os ON c.customer_id = os.customer_id
)

SELECT * FROM ltv
