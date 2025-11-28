/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/
USE marketing_dw;
GO 

-- ====================================================================
-- Checking 'gold.fact_spend'
-- ====================================================================
SELECT TOP 10 *
FROM gold.fact_spend;

-- Check for uniqueness of spend_key ✅
-- Expected results: None
SELECT
    spend_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_spend
GROUP BY spend_key 
HAVING COUNT(*) > 1;

-- Check for consitent dates ✅
-- Expected results: None
SELECT s.spend_date, s.date_key 
FROM gold.fact_spend s
LEFT JOIN gold.dim_date d
ON s.date_key = d.date_key
WHERE s.spend_date IS NULL OR s.date_key IS NULL OR s.spend_date != d.full_date;

-- Check consistency with dim_channel ✅
-- Expected results: None
SELECT *
FROM gold.fact_spend
WHERE channel NOT IN (
    SELECT channel_name
    FROM gold.dim_channel
); 

-- Check consitency with dim_campaign ✅
-- Expected results: None
SELECT 
    campaign_id, campaign_name 
FROM gold.fact_spend
WHERE campaign_id NOT IN (
    SELECT campaign_id 
    FROM gold.dim_campaign
) AND campaign_name NOT IN (
    SELECT campaign_name
    FROM gold.dim_campaign
);

-- Check objectives ✅
-- Expected results: NULL, Traffic, Conversion, Awareness
SELECT distinct objective
FROM gold.fact_spend;

-- Check for consisten spend values ✅
-- Expected results: None
SELECT spend 
FROM gold.fact_spend
WHERE spend IS NULL 
    OR spend <= 0

-- Check row count -> ❗️loaded into gold with filtering: spend_date NOT NULL and spend NOT NULL
-- Expected results: Different Counts
-- 1,073 - 1,185
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.mrkt_ad_spend) AS silver_rows
FROM gold.fact_spend;

-- ====================================================================
-- Checking 'gold.fact_clicks'
-- ====================================================================
SELECT TOP 10 *
FROM gold.fact_clicks;

-- Check for uniqueness of clicks_key ✅
-- Expected results: None
SELECT
    clicks_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_clicks
GROUP BY clicks_key 
HAVING COUNT(*) > 1;

-- Check for uniqueness of click_id ✅
-- Expected results: None
SELECT
    click_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_clicks
GROUP BY click_id 
HAVING COUNT(*) > 1;

-- Check for consitent timestamps ✅
-- Expected results: None
SELECT c.click_timestamp, c.date_key 
FROM gold.fact_clicks c
LEFT JOIN gold.dim_date d
ON c.date_key = d.date_key
WHERE c.click_timestamp IS NULL OR c.date_key IS NULL OR CAST(c.click_timestamp AS date) != d.full_date;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_clicks
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);

-- Check for user_id, click_channel and campaign_id as NOT NULL ✅
-- Expected results: None
SELECT user_id, click_channel, campaign_id 
FROM gold.fact_clicks
WHERE user_id IS NULL OR click_channel IS NULL OR campaign_id IS NULL;

-- Check for consitent acquisition channels ✅
-- Expected results: None
SELECT *
FROM gold.fact_clicks 
WHERE acquisition_channel NOT IN (
    SELECT acquisition_channel
    FROM silver.crm_user_acquisitions
);

-- Check row count -> ❗️loaded into gold with filtering: click_timestamp, channel, campaign_id and user_is as NOT NULL
-- Expected results: Different Counts
-- 70,366 - 81,437
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.mrkt_clicks) AS silver_rows
FROM gold.fact_clicks;

-- ====================================================================
-- Checking 'gold.fact_sessions'
-- ====================================================================
SELECT TOP 10 * 
FROM gold.fact_sessions

-- Check for uniqueness of session_key ✅
-- Expected results: None
SELECT
    session_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sessions
GROUP BY session_key 
HAVING COUNT(*) > 1;

-- Check for uniqueness of session_id ✅
-- Expected results: None
SELECT
    session_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_sessions
GROUP BY session_id 
HAVING COUNT(*) > 1;

-- Check for consitent dates and timestamps ✅
-- Expected results: None
SELECT s.session_date, s.session_start, d.full_date, s.date_key 
FROM gold.fact_sessions s
LEFT JOIN gold.dim_date d
ON s.date_key = d.date_key
WHERE s.session_date IS NULL 
    OR s.session_start IS NULL 
    OR s.date_key IS NULL 
    OR s.session_date != d.full_date 
    OR CAST(s.session_start AS date) != d.full_date;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_sessions
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);

-- Check for session_id, user_id, devive_category, source_channel, pages_viewed as NOT NULL ✅
-- Expected results: None
SELECT *
FROM gold.fact_sessions
WHERE session_id IS NULL OR user_id IS NULL OR device_category IS NULL OR source_channel IS NULL OR pages_viewed IS NULL;

-- Check for consitent acquisition channels ✅
-- Expected results: None
SELECT *
FROM gold.fact_sessions
WHERE acquisition_channel NOT IN (
    SELECT acquisition_channel
    FROM silver.crm_user_acquisitions
);

-- Check row count -> ❗️loaded into gold with filtering: session_start, user_id, pages_viewed, source_channel and device_category as NOT NULL
-- Expected results: Different Counts
-- 27,252 - 34,208
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.web_sessions) AS silver_rows
FROM gold.fact_sessions;

-- ====================================================================
-- Checking 'gold.fact_touchpoints'
-- ====================================================================
SELECT TOP 10 *
FROM gold.fact_touchpoints;

-- Check for uniqueness of touchpoint_key ✅
-- Expected results: None
SELECT
    touchpoint_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_touchpoints
GROUP BY touchpoint_key 
HAVING COUNT(*) > 1;

-- Check for consitent dates and timestamps ✅
-- Expected results: None
SELECT t.tp_date, t.touchpoint_time, d.full_date, t.date_key 
FROM gold.fact_touchpoints t
LEFT JOIN gold.dim_date d
ON t.date_key = d.date_key
WHERE t.tp_date IS NULL 
    OR t.touchpoint_time IS NULL 
    OR t.date_key IS NULL 
    OR t.tp_date != d.full_date 
    OR CAST(t.touchpoint_time AS date) != d.full_date;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_touchpoints
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);

-- Check consitency with dim_channel ✅
-- Expected results: None
SELECT *
FROM gold.fact_touchpoints
WHERE channel NOT IN (
    SELECT channel_name
    FROM gold.dim_channel
);

-- Check consitency with dim_campaign ✅
-- Expected results: None
SELECT campaign_id, campaign_name
FROM gold.fact_touchpoints
WHERE campaign_id NOT IN (
    SELECT campaign_id
    FROM gold.dim_campaign
);

-- Check for user_id, touchpoint_time,vinteraction_type and channel as NOT NULL ✅
-- Expected results: None
SELECT *
FROM gold.fact_touchpoints
WHERE user_id IS NULL 
    OR touchpoint_time IS NULL
    OR interaction_type IS NULL
    OR channel IS NULL

-- Check row count -> ❗️loaded into gold with filtering: user_id, touchpoint_time,vinteraction_type and channel as NOT NULL
-- Expected results: Different counts
-- 87,057 - 104,764
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.web_touchpoints) AS silver_rows
FROM gold.fact_touchpoints;

-- ====================================================================
-- Checking 'gold.fact_purchases'
-- ====================================================================
SELECT TOP 10 *
FROM gold.fact_purchases;

-- Check for uniqueness of purchase_key ✅
-- Expected results: None
SELECT
    purchase_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_purchases
GROUP BY purchase_key 
HAVING COUNT(*) > 1;

-- Check for uniqueness of purchase_id ✅
-- Expected results: None
SELECT
    purchase_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_purchases
GROUP BY purchase_id 
HAVING COUNT(*) > 1;

-- Check for consitent dates ✅
-- Expected results: None
SELECT p.purchase_date, d.full_date, p.date_key 
FROM gold.fact_purchases p
LEFT JOIN gold.dim_date d
ON p.date_key = d.date_key
WHERE p.purchase_date IS NULL 
    OR p.date_key IS NULL 
    OR p.purchase_date != d.full_date 

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_purchases
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);

-- Check consitency with dim_channel ✅
-- Expected results: None
SELECT *
FROM gold.fact_purchases
WHERE channel_last_touch NOT IN (
    SELECT channel_name
    FROM gold.dim_channel
);

-- Check for consitent acquisition channels, acquisition_date ✅
-- Expected results: None
SELECT *
FROM gold.fact_purchases
WHERE acquisition_channel NOT IN (
    SELECT acquisition_channel
    FROM silver.crm_user_acquisitions
);
SELECT *
FROM gold.fact_purchases p
LEFT JOIN silver.crm_user_acquisitions a
    ON p.user_id = a.user_id
   AND p.acquisition_date = a.acquisition_date
WHERE p.acquisition_date IS NOT NULL
  AND a.user_id IS NULL;   -- no matching acquisition row

-- Check for revenue values 
-- Expected results: Count_negatives equal count_positives ✅
-- 182 -182
-- Checking count of negatives
SELECT count_negatives 
FROM(
    SELECT COUNT(*) AS count_negatives
    FROM gold.fact_purchases
    WHERE TRY_CONVERT(DECIMAL(10,2), revenue) < 0)t

    -- Check if negative revenues correspond to positive revenues
    SELECT COUNT(*) AS count_positves
    FROM gold.fact_purchases p
    LEFT JOIN gold.fact_purchases r
        ON p.user_id = r.user_id
        AND TRY_CONVERT(DECIMAL(10,2), r.revenue) = 
            -TRY_CONVERT(DECIMAL(10,2), p.revenue)
    WHERE TRY_CONVERT(DECIMAL(10,2), p.revenue) < 0;

-- Check row count -> ❗️loaded into gold with filtering: purchase_id, user_id and purchase_date as NOT NULL
-- Expected results: Different counts
-- 3531 - 3923
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.crm_purchases) AS silver_rows
FROM gold.fact_purchases;
