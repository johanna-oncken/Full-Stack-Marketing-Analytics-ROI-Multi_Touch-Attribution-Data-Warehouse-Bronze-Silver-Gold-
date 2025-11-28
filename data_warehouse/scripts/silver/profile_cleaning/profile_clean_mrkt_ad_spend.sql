/*===============================================================================
Data Profiling and Cleaning Script: Bronze Ad Spend
Purpose:
    This script profiles and cleans raw data from bronze.mrkt_raw_ad_spend.
===============================================================================*/
USE marketing_dw;
GO


---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.mrkt_raw_ad_spend;


---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        date, channel, campaign_id, spend,
        COUNT(*) AS duplicates
    FROM bronze.mrkt_raw_ad_spend
    GROUP BY date, channel, campaign_id, spend
    HAVING COUNT(*) > 1
)t;

---------------------------------------------
-- 3) Date Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT date 
FROM bronze.mrkt_raw_ad_spend
WHERE LEN(date) != 10 

SELECT 
    DISTINCT date,
    CASE 
        WHEN date = 'not_available' THEN 'Missing'
        --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 dates
        WHEN SUBSTRING(date, 7, 4) = '2024' THEN 'DD.MM.YYYY format'
        WHEN TRY_CONVERT(DATE, date) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid Date Format'
    END AS date_status
FROM bronze.mrkt_raw_ad_spend
ORDER BY date_status;

-- > Cleaned column preview:
SELECT date AS raw_date,
        TRY_CONVERT(DATE,
        CASE 
            WHEN date = 'not_available' THEN NULL
            --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 dates
            WHEN SUBSTRING(date, 7, 4) = '2024' THEN '2024-' + SUBSTRING(date, 4, 2) + '-' + SUBSTRING(date,1,2)
            ELSE date
        END) AS spend_date
FROM bronze.mrkt_raw_ad_spend


---------------------------------------------
-- 4) Channel Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Comparing with channel names of raw_channels table
SELECT distinct channel 
FROM bronze.mrkt_raw_ad_spend
WHERE channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)

SELECT 
    channel,
    COUNT(*) AS occurrences
FROM bronze.mrkt_raw_ad_spend
GROUP BY channel
ORDER BY occurrences DESC;

-- > Cleaned column preview:
SELECT
    channel AS raw_channel,
    CASE 
        WHEN lower(channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
        WHEN lower(channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
        WHEN lower(channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
        WHEN lower(channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
        WHEN lower(channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
        ELSE channel
        END AS channel
FROM bronze.mrkt_raw_ad_spend


---------------------------------------------
-- 5) Campaign ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Comparing campaign ids with raw_campaigns table
SELECT distinct campaign_id
FROM bronze.mrkt_raw_ad_spend
WHERE campaign_id NOT IN(
    SELECT TRY_CONVERT(DECIMAL(10,2), campaign_id)
    FROM bronze.mrkt_raw_campaigns
)

SELECT
    campaign_id,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) IS NULL THEN 'Non-numeric'
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) = 0 THEN 'Zero/invalid'
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) > 53 THEN 'Out of range (>53)'
        ELSE 'Valid'
    END AS id_status,
    COUNT(*) AS occurrences
FROM bronze.mrkt_raw_ad_spend
GROUP BY campaign_id
ORDER BY id_status, campaign_id;

-- > Cleaned column preview:
SELECT 
    campaign_id AS raw_campaign_id,
    TRY_CONVERT(INT,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) IS NULL THEN NULL
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) = 0 THEN NULL
        -- raw_campaigns shows IDs up to 53
        WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) > 53 THEN NULL
        ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), campaign_id),0) 
    END) AS campaign_id
FROM bronze.mrkt_raw_ad_spend


---------------------------------------------
-- 6) Spend Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT
    spend,
    CASE 
        WHEN spend IS NULL THEN 'NULL'
        WHEN spend LIKE '%USD%' THEN 'Contains USD'
        WHEN spend LIKE '%"%' THEN 'Contains quotes'
        WHEN spend LIKE '%-%' THEN 'Contains hyphens (negative signs)'
        WHEN TRY_CONVERT(DECIMAL(10,2),
              TRIM(REPLACE(REPLACE(REPLACE(REPLACE(spend,'USD',''),'"',''),'-',''),',','.'))
        ) IS NULL THEN 'Non-numeric'
        ELSE 'Valid'
    END AS spend_status,
    COUNT(*) AS occurrences
FROM bronze.mrkt_raw_ad_spend
GROUP BY spend
ORDER BY spend_status;

-- > Cleaned column preview:
SELECT
    spend AS raw_spend,
    TRY_CONVERT(DECIMAL(10,2),
        TRIM(REPLACE(REPLACE(REPLACE((REPLACE(spend, 'USD', '')), '"', ''),'-', ''),',', '.'))) AS spend
FROM bronze.mrkt_raw_ad_spend


---------------------------------------------
-- 7) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.mrkt_raw_ad_spend
WHERE 
    (date IS NULL OR TRIM(date) = '')
 OR (channel IS NULL OR TRIM(channel) = '')
 OR (campaign_id IS NULL OR TRIM(campaign_id) = '')
 OR (spend IS NULL OR TRIM(spend) = '');




