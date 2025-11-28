/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. 

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/
USE marketing_dw;
GO 

-- ====================================================================
-- Checking 'silver.mrkt_ad_spend'
-- ====================================================================
SELECT TOP 5 *
FROM silver.mrkt_ad_spend 

-- Check for NULLs in spend_date ✅
-- Expected results: NULL results because of CASE transformations
SELECT 
    spend_date
FROM silver.mrkt_ad_spend
WHERE spend_date IS NULL

-- Check for consistent channel names ✅
-- Expected reults: Distinct, correctly written channels
SELECT
    distinct channel 
FROM silver.mrkt_ad_spend
--WHERE channel = TRIM(channel)

-- Check for consistent campaign_id ✅
-- Expected results: campaign ids under 53
SELECT distinct campaign_id 
FROM silver.mrkt_ad_spend
--WHERE campaign_id > 53

-- Check for NULLS or Negative Values in Costs ✅
-- Expected results: NULLs because of raw data
SELECT 
    spend 
FROM silver.mrkt_ad_spend 
WHERE spend IS NULL OR spend <= 0
-- NULLS; no negatives

-- ====================================================================
-- Checking 'silver.mrkt_campaigns'
-- ====================================================================
SELECT *
FROM silver.mrkt_campaigns

-- Check for NULLS or Duplicates in campaign_id ✅
-- Expected results: None
SELECT
    campaign_id, 
    COUNT(*) 
FROM silver.mrkt_campaigns
GROUP BY campaign_id 
HAVING COUNT(*) > 1 OR campaign_id IS NULL;

-- Check campaign_name ✅
-- Excepted results: Distinct, correctly written campaign names
-- Finding: One upper case name 'SUMMER_RETARGETING', corrected in proc_load_silver.sql
SELECT 
    distinct campaign_name 
FROM silver.mrkt_campaigns;
 
-- Check for consistent channels ✅
-- Excepted results: Distinct, correctly written channel names
SELECT distinct channel 
FROM silver.mrkt_campaigns 
--WHERE channel != trim(channel) 

-- Check for consistent objectives ✅
-- Excepted results: NULL; Awareness; Conversion; Traffic
SELECT distinct objective
FROM silver.mrkt_campaigns 
--WHERE objective != trim(objective) 


-- ====================================================================
-- Checking 'silver.mrkt_clicks'
-- ====================================================================
SELECT TOP 10 * 
FROM silver.mrkt_clicks

-- Check for NULLS or Duplicates in click_id ✅
-- Expected results: None
SELECT
    click_id, 
    COUNT(*) 
FROM silver.mrkt_clicks
GROUP BY click_id 
HAVING COUNT(*) > 1 OR click_id IS NULL;

-- Check user_id counts ✅
-- Expected results: Counts in all four categories, counts increasing from two_digit to four_digit
SELECT COUNT(*) AS null_counts,
    (SELECT COUNT(*) FROM silver.mrkt_clicks WHERE user_id < 100) AS two_digit,
    (SELECT COUNT(*) FROM silver.mrkt_clicks WHERE user_id < 1000 AND user_id > 99) AS three_digit,
    (SELECT COUNT(*) FROM silver.mrkt_clicks WHERE user_id > 1000 AND user_id > 99) AS four_digit
FROM silver.mrkt_clicks 
WHERE user_id IS NULL 

-- Check for consistent channels ✅
-- Expected results: Distinct, correctly written channel names
SELECT distinct channel 
FROM silver.mrkt_clicks 
--WHERE channel != trim(channel) 

-- Check for consistent campaign_id ✅
-- Expected results: campaign ids under 53
SELECT distinct campaign_id 
FROM silver.mrkt_clicks
--WHERE campaign_id > 53

-- Check unreasonable duplicate timestamps ✅
-- Expected results: No counts, except NULL count
SELECT distinct click_timestamp,
    COUNT(*)
FROM silver.mrkt_clicks
--WHERE click_timestamp IS NULL
GROUP BY click_timestamp
HAVING COUNT(*) > 5


-- ====================================================================
-- Checking 'silver.web_sessions'
-- ====================================================================
SELECT TOP 10 *
FROM silver.web_sessions

-- Check for NULLS or Duplicates in session_id ✅
-- Expected results: None
SELECT
    session_id, 
    COUNT(*) 
FROM silver.web_sessions
GROUP BY session_id 
HAVING COUNT(*) > 1 OR session_id IS NULL;

-- Check user_id counts ✅
-- Expected results: Counts in all four categories, counts increasing from two_digit to four_digit
SELECT COUNT(*) AS null_counts,
    (SELECT COUNT(*) FROM silver.web_sessions WHERE user_id < 100) AS two_digit,
    (SELECT COUNT(*) FROM silver.web_sessions WHERE user_id < 1000 AND user_id > 99) AS three_digit,
    (SELECT COUNT(*) FROM silver.web_sessions WHERE user_id > 1000 AND user_id > 99) AS four_digit
FROM silver.web_sessions
WHERE user_id IS NULL 

-- Check unreasonable duplicate timestamps ✅
-- Expected results: No counts, except NULL count
SELECT distinct session_start,
    COUNT(*)
FROM silver.web_sessions
GROUP BY session_start
HAVING COUNT(*) > 3; 

-- Check device ✅
-- Expected results: Counts for NULL, Desktop, Mobile, Tablet
SELECT distinct device, COUNT(*) 
FROM silver.web_sessions 
GROUP BY device 

-- Check for consistent source_channels ✅
-- Expected results: Distinct, corretly written channel names, NULL included
SELECT distinct source_channel 
FROM silver.web_sessions
--WHERE source_channel != trim(source_channel) 

-- Check consistent pages_viewed ✅
-- Expected results: None
SELECT pages_viewed 
FROM silver.web_sessions
WHERE pages_viewed < 1 OR pages_viewed > 15


-- ====================================================================
-- Checking 'silver.web_touchpoints'
-- ====================================================================
SELECT TOP 10 * 
FROM silver.web_touchpoints;

-- Check user_id counts ✅
-- Expected results: Counts in all four categories, counts increasing from two_digit to four_digit
SELECT COUNT(*) AS null_counts,
    (SELECT COUNT(*) FROM silver.web_touchpoints WHERE user_id < 100) AS two_digit,
    (SELECT COUNT(*) FROM silver.web_touchpoints WHERE user_id < 1000 AND user_id > 99) AS three_digit,
    (SELECT COUNT(*) FROM silver.web_touchpoints WHERE user_id > 1000 AND user_id > 99) AS four_digit
FROM silver.web_touchpoints
WHERE user_id IS NULL 

-- Check unreasonable duplicate timestamps ✅
-- Expected results: No counts, except NULL count
SELECT distinct touchpoint_time,
    COUNT(*)
FROM silver.web_touchpoints
GROUP BY touchpoint_time
HAVING COUNT(*) > 3; 

-- Check for consistent channels ✅
-- Expected results: Distinct, corretly written channel names, NULL included
SELECT distinct channel 
FROM silver.web_touchpoints 
--WHERE channel != trim(channel) 

-- Check for consistent campaign_id ✅ 
-- Expected results: Campaign ids under 53
SELECT distinct campaign_id 
FROM silver.web_touchpoints
--WHERE campaign_id > 53

-- Check for interaction_type ✅ 
-- Expected results: Counts for Null, View, Impression, Click
SELECT distinct interaction_type, COUNT(*)
FROM silver.web_touchpoints
GROUP BY interaction_type
    -- -> Finding: Two versions 'impressions and Impression'
    -- -> Corrected in proc_load_silver.sql


-- ====================================================================
-- Checking 'silver.crm_channels'
-- ====================================================================
SELECT *
FROM silver.crm_channels
-- Small table, everything looks fine ✅


-- ====================================================================
-- Checking 'silver.crm_purchases'
-- ====================================================================
SELECT TOP 10 * 
FROM silver.crm_purchases

-- Check for NULLS or Duplicates in purchase_id ✅
-- Expected results: None
SELECT
    purchase_id, 
    COUNT(*) 
FROM silver.crm_purchases
GROUP BY purchase_id 
HAVING COUNT(*) > 1 OR purchase_id IS NULL;

-- Check user_id count ✅
-- Expected results: Counts in all four categories, counts increasing from two_digit to four_digit
SELECT COUNT(*) AS null_counts,
    (SELECT COUNT(*) FROM silver.crm_purchases WHERE user_id < 100) AS two_digit,
    (SELECT COUNT(*) FROM silver.crm_purchases WHERE user_id < 1000 AND user_id > 99) AS three_digit,
    (SELECT COUNT(*) FROM silver.crm_purchases WHERE user_id > 1000 AND user_id > 99) AS four_digit
FROM silver.crm_purchases
WHERE user_id IS NULL; 

-- Check purchase_date ✅
-- Expected results: Purchase dates in 2024, NULLS included
SELECT distinct purchase_date, COUNT(*)
FROM silver.crm_purchases
GROUP BY purchase_date

-- Check for unreasonable revenue values ✅
-- Expected results: None
SELECT revenue 
FROM silver.crm_purchases 
WHERE revenue > 300 OR (revenue < 10 AND revenue > 0)

    -- Checking count of negatives
    -- Expected results: 200 - 5.1%
    SELECT count_negatives, 
        (SELECT ROUND(TRY_CONVERT(DECIMAL(10,2), 200)/3923*100,2)) AS percentage_negatives
    FROM(
        SELECT COUNT(*) AS count_negatives
        FROM silver.crm_purchases
        WHERE TRY_CONVERT(DECIMAL(10,2), revenue) < 0)t

    -- Check if they are return = if negative revenues correspond to positive revenues ✅
    -- Expected results: 200
    SELECT COUNT(*)
    FROM silver.crm_purchases p
    LEFT JOIN silver.crm_purchases r
        ON p.user_id = r.user_id
        AND TRY_CONVERT(DECIMAL(10,2), r.revenue) = 
            -TRY_CONVERT(DECIMAL(10,2), p.revenue)
    WHERE TRY_CONVERT(DECIMAL(10,2), p.revenue) < 0;

-- Check for consistent channels ✅
-- Expected results: Distinct, correctly written channels names, NULLs included
SELECT distinct channel_last_touch 
FROM silver.crm_purchases
--WHERE channel_last_touch != trim(channel_last_touch) 

-- > Finding: emtpy space 
-- > Corrected in proc_load_silver.sql 


-- ====================================================================
-- Checking 'silver.crm_user_acquisitions'
-- ====================================================================
SELECT TOP 10 * 
FROM silver.crm_user_acquisitions;

-- Check for NULLS or Duplicates in user_id ✅
-- Expected results: None
SELECT
    user_id, 
    COUNT(*) 
FROM silver.crm_user_acquisitions
GROUP BY user_id 
HAVING COUNT(*) > 1 OR user_id IS NULL;

-- Check user_id counts ✅
-- Expected results: 0 NULLs, 9 one_digit, 99 two_digit, 900 three_digit and count of four_digit > count of three_digit
SELECT COUNT(*) AS null_counts,
    (SELECT COUNT(*) FROM silver.crm_user_acquisitions WHERE user_id < 10) AS one_digit,
    (SELECT COUNT(*) FROM silver.crm_user_acquisitions WHERE user_id < 100) AS two_digit,
    (SELECT COUNT(*) FROM silver.crm_user_acquisitions WHERE user_id < 1000 AND user_id > 99) AS three_digit,
    (SELECT COUNT(*) FROM silver.crm_user_acquisitions WHERE user_id > 1000 AND user_id > 99) AS four_digit,
    (SELECT COUNT(*) FROM silver.crm_user_acquisitions WHERE user_id > 10000 AND user_id > 99) AS five_digit
FROM silver.crm_user_acquisitions
WHERE user_id IS NULL; 

-- Check acquisition_date ✅
-- Expected results, acquisition dates in 2024 and 2023, NULLs included
SELECT distinct acquisition_date, COUNT(*)
FROM silver.crm_user_acquisitions
GROUP BY acquisition_date

-- Check for consistent channels ✅
-- Expected results: Distinct, correctly written channel_names, NULL included
SELECT distinct acquisition_channel
FROM silver.crm_user_acquisitions
--WHERE acquisition_channel != trim(acquisition_channel) 

-- Check for consistent campaign_id ✅
-- Expected results: Campaign ids under 53
SELECT distinct acquisition_campaign
FROM silver.crm_user_acquisitions
--WHERE acquisition_campaign > 53

