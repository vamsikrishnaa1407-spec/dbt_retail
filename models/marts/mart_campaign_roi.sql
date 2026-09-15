-- mart_campaign_roi.sql
-- Campaign return on investment analytics
-- Source: stg_campaigns (which already aggregates responses)

WITH campaigns AS (
    SELECT * FROM {{ ref('stg_campaigns') }}
),

roi AS (
    SELECT
        campaign_id,
        campaign_name,
        channel,
        campaign_type,
        target_segment_id,
        start_date,
        end_date,
        budget,
        spend,
        total_responses,
        total_purchases,
        revenue_attributed,
        roi_pct,
        CASE
            WHEN total_purchases > 0
            THEN ROUND(spend / total_purchases, 2)
            ELSE NULL
        END                                     AS cost_per_conversion,
        CASE
            WHEN total_responses > 0
            THEN ROUND(total_purchases * 100.0 / total_responses, 2)
            ELSE 0
        END                                     AS conversion_rate_pct,
        status,
        CURRENT_TIMESTAMP()                     AS _dbt_run_at
    FROM campaigns
)

SELECT * FROM roi
