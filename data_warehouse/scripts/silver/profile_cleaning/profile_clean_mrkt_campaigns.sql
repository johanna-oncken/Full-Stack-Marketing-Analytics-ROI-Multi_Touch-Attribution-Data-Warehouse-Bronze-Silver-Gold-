/*===============================================================================
Data Profiling and Cleaning Script: Bronze Campaigns
Purpose:
    This script profiles and cleans raw data from bronze.mrkt_raw_campaigns.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.mrkt_raw_campaigns;


---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        campaign_id, campaign_name, channel, start_date, end_date, objective,
        COUNT(*) AS duplicates
    FROM bronze.mrkt_raw_campaigns
    GROUP BY campaign_id, campaign_name, channel, start_date, end_date, objective
    HAVING COUNT(*) > 1
)t;

---------------------------------------------
-- 3) ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- only 53 rows and 53 ids
SELECT campaign_id
FROM bronze.mrkt_raw_campaigns
GROUP BY campaign_id
HAVING COUNT(campaign_id) > 1

-- > Cleaned column preview
SELECT campaign_id AS raw_campaign_id,
    TRY_CONVERT(INT, campaign_id) AS campaign_id
FROM bronze.mrkt_raw_campaigns


---------------------------------------------
-- 4) Campaign Names Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT campaign_name,
    CASE 
        WHEN campaign_name IS NULL THEN 'Missing'
        --decided to rename some summer campaigns because of unrealtistic start dates and/or end dates
        WHEN (campaign_name = 'Summer_Launch' AND start_date = '2023-12-30') OR (campaign_name = 'SUMMER_RETARGETING'AND end_date = '2024-01-26')  
        THEN 'Rename'
        WHEN campaign_name = 'SUMMER_RETARGETING' AND (end_date = '2024-03-30' OR end_date = '2024-03-26') THEN 'Rename'
        ELSE 'Valid'
    END AS status_campaign_name
FROM bronze.mrkt_raw_campaigns

SELECT campaign_name, start_date, end_date
FROM bronze.mrkt_raw_campaigns
WHERE campaign_name = 'SUMMER_RETARGETING'

-- > Cleaned column preview
SELECT campaign_name AS raw_campaign_name,
    CASE 
        --decided to rename some summer campaigns because of unrealtistic start dates and/or end dates
        WHEN (campaign_name = 'Summer_Launch' 
            AND start_date = '2023-12-30') 
        OR (campaign_name = 'SUMMER_RETARGETING'
            AND end_date = '2024-01-26')  
            THEN 'New_Year_Launch'
        WHEN campaign_name = 'SUMMER_RETARGETING' 
            AND end_date IN ('2024-03-30','2024-03-26')
            THEN 'Brand_Awareness_Q1'
        ELSE TRIM(campaign_name)
    END AS campaign_name
FROM bronze.mrkt_raw_campaigns


---------------------------------------------
-- 5) Channel Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning channel column in mrkt_raw_ad_spend
SELECT distinct channel 
FROM bronze.mrkt_raw_campaigns
WHERE channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)

SELECT 
    channel,
    COUNT(*) AS occurrences
FROM bronze.mrkt_raw_campaigns
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
FROM bronze.mrkt_raw_campaigns


---------------------------------------------
-- 6) Start Date Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying similar date logic as in cleaning date column in mrkt_raw_ad_spend
SELECT start_date 
FROM bronze.mrkt_raw_campaigns
WHERE LEN(start_date) != 10 

SELECT 
    DISTINCT start_date,
    CASE 
        WHEN start_date = 'not_available' THEN 'Missing'
        --Checking for left to right format DD.MM.YYYY
        WHEN SUBSTRING(start_date, 7, 4) IN ('2023','2024') THEN 'DD.MM.YYYY format'
        WHEN TRY_CONVERT(DATE, start_date) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid Date Format'
    END AS status_start_date
FROM bronze.mrkt_raw_campaigns
ORDER BY status_start_date;

-- > Cleaned column preview:
SELECT start_date AS raw_start_date,
        TRY_CONVERT(DATE,
        CASE 
            WHEN start_date = 'not_available' THEN NULL
            --Checking for left to right format DD.MM.YYYY
            WHEN SUBSTRING(start_date, 7, 4) IN ('2023', '2024') THEN SUBSTRING(start_date, 7, 4) + '-' + SUBSTRING(start_date, 4, 2) + '-' + SUBSTRING(start_date,1,2)
            ELSE start_date
        END) AS start_date
FROM bronze.mrkt_raw_campaigns


---------------------------------------------
-- 7) End Date Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying similar date logic 
SELECT end_date 
FROM bronze.mrkt_raw_campaigns
WHERE LEN(end_date) != 10 

SELECT 
    DISTINCT end_date,
    CASE 
        WHEN end_date = 'not_available' THEN 'Missing'
        --Checking for left to right format DD.MM.YYYY
        WHEN SUBSTRING(end_date, 7, 4) IN ('2023','2024') THEN 'DD.MM.YYYY format'
        WHEN TRY_CONVERT(DATE, end_date) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid Date Format'
    END AS status_end_date
FROM bronze.mrkt_raw_campaigns
ORDER BY status_end_date;

-- > Cleaned column preview:
SELECT end_date AS raw_end_date,
        TRY_CONVERT(DATE,
        CASE 
            WHEN end_date = 'not_available' THEN NULL
            --Checking for left to right format DD.MM.YYYY
            WHEN SUBSTRING(end_date, 7, 4) IN ('2023', '2024') THEN SUBSTRING(end_date, 7, 4) + '-' + SUBSTRING(end_date, 4, 2) + '-' + SUBSTRING(end_date,1,2)
            ELSE end_date
        END) AS end_date
FROM bronze.mrkt_raw_campaigns


---------------------------------------------
-- 8) Objective Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Shows three main objectives: Awareness, Conversion, Traffic and NULL
SELECT distinct TRIM(LOWER(objective))
FROM bronze.mrkt_raw_campaigns 

SELECT DISTINCT objective,
    CASE 
        WHEN objective IS NULL THEN 'Missing'
        ELSE 'Valid'
    END AS status_objective
FROM bronze.mrkt_raw_campaigns 

-- > Cleaned column preview:
SELECT objective AS raw_objective,
    CASE 
        WHEN objective IS NULL THEN NULL
        WHEN TRIM(LOWER(objective)) LIKE 'aware%' THEN 'Awareness'
        WHEN TRIM(LOWER(objective)) LIKE 'conv%' THEN 'Conversion'
        WHEN TRIM(LOWER(objective)) = 'traffic' THEN 'Traffic'
        ELSE objective 
    END AS objective 
FROM bronze.mrkt_raw_campaigns 


---------------------------------------------
-- 9) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.mrkt_raw_campaigns 
WHERE
    (campaign_id IS NULL OR TRIM(campaign_id) = '')
 OR (campaign_name IS NULL OR TRIM(campaign_name) = '')
 OR (channel IS NULL OR TRIM(channel) = '')
 OR (start_date IS NULL OR TRIM(start_date) = '')
 OR (end_date IS NULL OR TRIM(end_date) = '')
 OR (objective IS NULL OR TRIM(objective) = '');
