-- stg_customer_addresses.sql
-- Staging model: clean and join addresses with customer region
-- Source: RAW_DB.crm.customer_addresses (landed from PostgreSQL via ADF)

WITH addresses AS (
    SELECT * FROM {{ source('crm', 'customer_addresses') }}
),

customers AS (
    SELECT customer_id, region FROM {{ source('crm', 'customers') }}
),

cleaned AS (
    SELECT
        a.address_id,
        a.customer_id,
        c.region                                         AS customer_region,
        a.address_type,
        a.address_line1,
        COALESCE(a.address_line2, '')                    AS address_line2,
        a.city,
        COALESCE(a.county, '')                           AS county,
        UPPER(REPLACE(a.postcode, ' ', ''))              AS postcode_clean,
        a.postcode,
        a.country,
        a.is_default,
        a.created_at,
        CURRENT_TIMESTAMP()                              AS _dbt_run_at
    FROM addresses a
    LEFT JOIN customers c ON a.customer_id = c.customer_id
)

SELECT * FROM cleaned
