-- stg_products.sql
-- Staging model: products with category name resolved and margin computed
-- Sources: RAW_DB.ecommerce.products + stg_categories

WITH products AS (
    SELECT * FROM {{ source('ecommerce', 'products') }}
),

cats AS (
    SELECT category_id, category_name, parent_category_name, category_level
    FROM {{ ref('stg_categories') }}
),

enriched AS (
    SELECT
        p.product_id,
        p.category_id,
        c.category_name,
        c.parent_category_name,
        c.category_level,
        p.sku,
        p.product_name,
        p.price,
        p.cost,
        ROUND((p.price - p.cost) / NULLIF(p.price, 0) * 100, 2)  AS margin_pct,
        p.stock_qty,
        CASE WHEN p.stock_qty <= 20 THEN TRUE ELSE FALSE END       AS is_low_stock,
        p.is_active,
        p.created_at,
        p.updated_at,
        CURRENT_TIMESTAMP()                                        AS _dbt_run_at
    FROM products p
    LEFT JOIN cats c ON p.category_id = c.category_id
    WHERE p.is_active = TRUE
)

SELECT * FROM enriched
