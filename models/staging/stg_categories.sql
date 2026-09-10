-- stg_categories.sql
-- Staging model: product category hierarchy with parent name resolved
-- Source: RAW_DB.ecommerce.categories (landed from MySQL via ADF)

WITH categories AS (
    SELECT * FROM {{ source('ecommerce', 'categories') }}
),

hierarchy AS (
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        p.category_name                                  AS parent_category_name,
        c.slug,
        CASE
            WHEN c.parent_category_id IS NULL THEN 'top_level'
            ELSE 'sub_category'
        END                                              AS category_level,
        c.sort_order,
        c.is_active,
        c.created_at,
        CURRENT_TIMESTAMP()                              AS _dbt_run_at
    FROM categories c
    LEFT JOIN categories p ON c.parent_category_id = p.category_id
)

SELECT * FROM hierarchy
