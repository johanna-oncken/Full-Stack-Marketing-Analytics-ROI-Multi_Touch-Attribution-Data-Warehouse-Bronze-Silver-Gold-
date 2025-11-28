/*===============================================================================
Data Profiling and Cleaning Script: Bronze Touchpoints
Purpose:
    This script profiles and cleans raw data from bronze.web_raw_touchpoints.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.web_raw_touchpoints;
-- 104772 rows


---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        user_id, touchpoint_time, channel, campaign_id, interaction_type,
        COUNT(*) AS duplicates
    FROM bronze.web_raw_touchpoints
    GROUP BY user_id, touchpoint_time, channel, campaign_id, interaction_type
    HAVING COUNT(*) > 1
)t;
-- 5 duplicate rows

---------------------------------------------
-- 3) USER ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Appyling logic from cleaning user_id column in touchpoints table
-- Checking for unrealistic user counts
SELECT user_id, COUNT(user_id) AS user_count
FROM bronze.web_raw_touchpoints
GROUP BY user_id
HAVING COUNT(user_id) > 100; 

-- Checking for missing user ids
SELECT user_id, COUNT(user_id)
FROM bronze.web_raw_touchpoints
WHERE user_id IS NULL
GROUP BY user_id;

-- Fine, because not all users are acquired
SELECT user_id 
FROM bronze.web_raw_touchpoints
WHERE user_id NOT IN (
    SELECT user_id 
    FROM bronze.crm_raw_user_acquisitions
);

-- > Cleaned column preview
SELECT user_id AS raw_user_id,
    TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id
FROM bronze.web_raw_touchpoints;


---------------------------------------------
-- 4) TOUCHPOINT TIME Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning timestamp column in touchpoints table
-- Check if there is an unrealistic count of duplicate timestamps
SELECT DISTINCT touchpoint_time, COUNT(*)
FROM bronze.web_raw_touchpoints
GROUP BY touchpoint_time
HAVING COUNT(*) > 1;

SELECT 
    touchpoint_time,
    CASE
        WHEN touchpoint_time IS NULL THEN 'Missing'
        WHEN touchpoint_time = 'invalid' THEN 'Invalid'
        WHEN touchpoint_time LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
         AND LEN(touchpoint_time) = 16
            THEN 'Valid - DD/MM/YYYY HH:MM format'
        ELSE 'Valid - YYYY-MM-DD HH:MM:SS format'
    END AS status_touchpoint_time
FROM bronze.web_raw_touchpoints;

-- > Cleaned column preview
SELECT  
    touchpoint_time AS raw_touchpoint_time,
    TRY_CONVERT(DATETIME2,
    CASE 
        WHEN touchpoint_time IS NULL or touchpoint_time = 'invalid' THEN NULL
        WHEN touchpoint_time LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
            AND LEN(touchpoint_time) = 16
            THEN CONCAT(SUBSTRING(touchpoint_time, 7, 4), '-', SUBSTRING(touchpoint_time, 4, 2), '-', SUBSTRING(touchpoint_time, 1, 2), ' ', SUBSTRING(touchpoint_time, 12, 5), ':00')
        ELSE TRIM(touchpoint_time)
    END) AS touchpoint_time
FROM bronze.web_raw_touchpoints;


---------------------------------------------
-- 5) CHANNEL Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Modifying logic from cleaning channel columns in ad_spend and campaigns table
SELECT distinct channel   
FROM bronze.web_raw_touchpoints
WHERE channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)
ORDER BY channel;

SELECT 
    channel,
    COUNT(*) AS occurrences
FROM bronze.web_raw_touchpoints
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
        WHEN lower(channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
        WHEN lower(channel) IN ('referal', 'referral') THEN 'Referral'
        ELSE channel
    END AS channel
FROM bronze.web_raw_touchpoints;


---------------------------------------------
-- 6) CAMPAIGN ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning campaign_column in ad_spend table
-- Comparing campaign ids with raw_campaigns table
SELECT distinct campaign_id
FROM bronze.web_raw_touchpoints
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
FROM bronze.web_raw_touchpoints
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
FROM bronze.web_raw_touchpoints


---------------------------------------------
-- 7) INTERACTIVE TYPE Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT interaction_type, COUNT(*) AS occurences 
FROM bronze.web_raw_touchpoints
GROUP BY interaction_type
ORDER BY interaction_type

-- > Cleaned column preview:
SELECT 
    interaction_type AS raw_interaction_type,
    CASE 
        WHEN interaction_type is NULL THEN NULL 
        WHEN LOWER(interaction_type) IN ('click', 'clik', 'clk') THEN 'Click'
        WHEN LOWER(interaction_type) IN ('impr', 'impression', 'Impression') THEN 'Impression'
        WHEN LOWER(interaction_type) IN ('page_view', 'view') THEN 'View' 
        ELSE interaction_type 
    END AS interaction_type
FROM bronze.web_raw_touchpoints;


---------------------------------------------
-- 8) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.web_raw_touchpoints
WHERE
    (user_id IS NULL OR TRIM(user_id) = '')
 OR (touchpoint_time IS NULL OR TRIM(touchpoint_time) = '')
 OR (channel IS NULL OR TRIM(channel) = '')
 OR (campaign_id IS NULL OR TRIM(campaign_id) = '')
 OR (interaction_type IS NULL OR TRIM(interaction_type) = '');

