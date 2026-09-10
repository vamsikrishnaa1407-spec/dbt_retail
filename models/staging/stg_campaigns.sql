-- stg_campaigns.sql
-- Source: RAW_DB.crm.campaigns + campaign_responses (loaded by ADF from PostgreSQL)
-- Target: STAGING_DB.retail.stg_campaigns

WITH campaigns AS (
    SELECT * FROM {{ source('crm', 'campaigns') }}
),

response_agg AS (
    SELECT
        campaign_id,
        COUNT(*)                                                AS total_responses,
        SUM(CASE WHEN response_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
        SUM(revenue_attr)                                       AS revenue_attributed
    FROM {{ source('crm', 'campaign_responses') }}
    GROUP BY campaign_id
),

joined AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        c.channel,
        c.campaign_type,
        c.target_segment,
        c.start_date,
        c.end_date,
        c.budget,
        c.spend,
        COALESCE(ra.total_responses, 0)                         AS total_responses,
        COALESCE(ra.purchases, 0)                               AS total_purchases,
        COALESCE(ra.revenue_attributed, 0)                      AS revenue_attributed,
        CASE
            WHEN c.spend > 0
            THEN ROUND((COALESCE(ra.revenue_attributed, 0) - c.spend) / c.spend * 100, 2)
            ELSE 0
        END                                                     AS roi_pct,
        c.status,
        c.created_at,
        CURRENT_TIMESTAMP()                                     AS _dbt_loaded_at,
        'crm.campaigns'                                         AS _source
    FROM campaigns c
    LEFT JOIN response_agg ra ON c.campaign_id = ra.campaign_id
)

SELECT * FROM joined
