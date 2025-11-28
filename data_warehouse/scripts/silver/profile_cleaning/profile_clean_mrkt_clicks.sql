/*===============================================================================
Data Profiling and Cleaning Script: Bronze Clicks
Purpose:
    This script profiles and cleans raw data from bronze.mrkt_raw_clicks.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.mrkt_raw_clicks;


---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        click_id, user_id, channel, campaign_id, timestamp,
        COUNT(*) AS duplicates
    FROM bronze.mrkt_raw_clicks
    GROUP BY click_id, user_id, channel, campaign_id, timestamp
    HAVING COUNT(*) > 1
)t;


---------------------------------------------
-- 3) CLICK ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT click_id 
FROM bronze.mrkt_raw_clicks
GROUP BY click_id
HAVING COUNT(click_id) > 1;

-- > Cleaned column preview
SELECT click_id AS raw_click_id,
    TRY_CONVERT(INT, click_id) AS click_id
FROM bronze.mrkt_raw_clicks;


---------------------------------------------
-- 4) USER ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Checking for unrealistic click counts
SELECT user_id, COUNT(user_id) 
FROM bronze.mrkt_raw_clicks
GROUP BY user_id
HAVING COUNT(user_id) > 100;

-- Checking for missing user ids
SELECT user_id, COUNT(user_id)
FROM bronze.mrkt_raw_clicks
WHERE user_id IS NULL
GROUP BY user_id;

-- Fine, because not all users are acquired
SELECT user_id 
FROM bronze.mrkt_raw_clicks
WHERE user_id NOT IN (
    SELECT user_id 
    FROM bronze.crm_raw_user_acquisitions
);

-- > Cleaned column preview
SELECT user_id AS raw_user_id,
    TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id
FROM bronze.mrkt_raw_clicks;



---------------------------------------------
-- 5) CHANNEL Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning channel columns in ad_spend and campaigns table
SELECT distinct channel 
FROM bronze.mrkt_raw_clicks
WHERE channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
);

SELECT 
    channel,
    COUNT(*) AS occurrences
FROM bronze.mrkt_raw_clicks
GROUP BY channel
ORDER BY occurrences DESC;

-- > Cleaned column preview
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
FROM bronze.mrkt_raw_clicks;



---------------------------------------------
-- 6) CAMPAIGN ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning campaign_column in ad_spend table
-- Comparing campaign ids with raw_campaigns table
SELECT distinct campaign_id
FROM bronze.mrkt_raw_clicks
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
FROM bronze.mrkt_raw_clicks
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
FROM bronze.mrkt_raw_clicks


---------------------------------------------
-- 7) TIMESTAMP Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Check if there is an unrealistic count of duplicate timestamps
SELECT DISTINCT timestamp, COUNT(timestamp)
FROM bronze.mrkt_raw_clicks
GROUP BY timestamp
HAVING COUNT(timestamp) > 1;

SELECT 
    timestamp,
    CASE
        WHEN timestamp IS NULL THEN 'Missing'
        WHEN timestamp = 'invalid_date' THEN 'Invalid'
        WHEN timestamp LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
         AND LEN(timestamp) = 16
            THEN 'Valid - DD/MM/YYYY HH:MM format'
        ELSE 'Valid - YYYY-MM-DD HH:MM:SS format'
    END AS status_timestamp
FROM bronze.mrkt_raw_clicks;

-- > Cleaned column preview
SELECT  
    timestamp AS raw_timestamp,
    TRY_CONVERT(DATETIME2,
    CASE 
        WHEN timestamp IS NULL or timestamp = 'invalid_date' THEN NULL
        WHEN timestamp LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
            AND LEN(timestamp) = 16
            THEN CONCAT(SUBSTRING(timestamp, 7, 4), '-', SUBSTRING(timestamp, 4, 2), '-', SUBSTRING(timestamp, 1, 2), ' ', SUBSTRING(timestamp, 12, 5), ':00')
        ELSE TRIM(timestamp)
    END) AS click_timestamp
FROM bronze.mrkt_raw_clicks;


---------------------------------------------
-- 8) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.mrkt_raw_clicks 
WHERE
    (click_id IS NULL OR TRIM(click_id) = '')
 OR (user_id IS NULL OR TRIM(user_id) = '')
 OR (channel IS NULL OR TRIM(channel) = '')
 OR (campaign_id IS NULL OR TRIM(campaign_id) = '')
 OR (timestamp IS NULL OR TRIM(timestamp) = '');
