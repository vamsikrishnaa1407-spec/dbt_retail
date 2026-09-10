-- mart_revenue.sql
-- Revenue by date / region / channel / loyalty tier
-- Sources: stg_customers + stg_orders

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

joined AS (
    SELECT
        o.order_date,
        c.region,
        c.acquisition_channel               AS channel,
        c.loyalty_tier,
        o.order_id,
        o.customer_id,
        o.total_amount
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
),

aggregated AS (
    SELECT
        order_date                          AS revenue_date,
        region,
        COALESCE(channel, 'unknown')        AS channel,
        COALESCE(loyalty_tier, 'UNKNOWN')   AS loyalty_tier,
        COUNT(DISTINCT order_id)            AS order_count,
        COUNT(DISTINCT customer_id)         AS customer_count,
        SUM(total_amount)                   AS total_revenue,
        AVG(total_amount)                   AS avg_order_value,
        CURRENT_TIMESTAMP()                 AS _dbt_run_at
    FROM joined
    GROUP BY 1, 2, 3, 4
)

SELECT * FROM aggregated
