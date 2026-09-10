-- stg_customers.sql
-- Staging model: cleaned customer master joined with segment details
-- Sources: RAW_DB.crm.customers + RAW_DB.crm.customer_segments

WITH customers AS (
    SELECT * FROM {{ source('crm', 'customers') }}
),

segments AS (
    SELECT * FROM {{ source('crm', 'customer_segments') }}
),

cleaned AS (
    SELECT
        c.customer_id,
        c.segment_id,
        s.segment_name,
        s.discount_rate,
        s.priority_support,
        c.first_name,
        c.last_name,
        c.first_name || ' ' || c.last_name              AS full_name,
        LOWER(c.email)                                   AS email,
        c.phone,
        UPPER(c.loyalty_tier)                            AS loyalty_tier,
        c.region,
        c.acquisition_channel,
        COALESCE(c.lifetime_value, 0)                    AS lifetime_value,
        c.customer_since,
        c.is_active,
        c.created_at,
        c.updated_at,
        CURRENT_TIMESTAMP()                              AS _dbt_run_at
    FROM customers c
    LEFT JOIN segments s ON c.segment_id = s.segment_id
    WHERE c.is_active = TRUE
)

SELECT * FROM cleaned
