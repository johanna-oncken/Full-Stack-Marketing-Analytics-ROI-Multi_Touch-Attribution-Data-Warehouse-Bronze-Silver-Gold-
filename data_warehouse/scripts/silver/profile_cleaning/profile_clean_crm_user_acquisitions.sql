/*===============================================================================
Data Profiling and Cleaning Script: Bronze USER ACQUISITIONS
Purpose:
    This script profiles and cleans raw data from bronze.crm_raw_user_acquisitions.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.crm_raw_user_acquisitions;



---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        user_id, acquisition_date, acquisition_channel, acquisition_campaign,
        COUNT(*) AS duplicates
    FROM bronze.crm_raw_user_acquisitions
    GROUP BY user_id, acquisition_date, acquisition_channel, acquisition_campaign
    HAVING COUNT(*) > 1
)t;


---------------------------------------------
-- 3) USER ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning user_id column in touchpoints table
-- Checking for unrealistic user counts
SELECT user_id, COUNT(user_id) AS user_count
FROM bronze.crm_raw_user_acquisitions
GROUP BY user_id
HAVING COUNT(user_id) > 100; 

-- Checking for missing user ids
SELECT user_id, COUNT(user_id)
FROM bronze.crm_raw_user_acquisitions
WHERE user_id IS NULL OR user_id = ''
GROUP BY user_id;


-- > Cleaned column preview
SELECT user_id AS raw_user_id,
    TRY_CONVERT(INT, user_id) AS user_id
FROM bronze.crm_raw_user_acquisitions;


---------------------------------------------
-- 4) ACQUISITION DATE Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning date column in ad spend table
SELECT acquisition_date 
FROM bronze.crm_raw_user_acquisitions
WHERE LEN(acquisition_date) != 10 

SELECT 
    DISTINCT acquisition_date,
    CASE 
        WHEN acquisition_date = 'invalid' THEN 'Missing'
        --Checking for left to right format DD.MM.YYYY
        WHEN SUBSTRING(acquisition_date, 7, 4) IN ('2023', '2024') THEN 'DD.MM.YYYY format'
        WHEN TRY_CONVERT(DATE, acquisition_date) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid acquisition_date Format'
    END AS status_acquisition_date
FROM bronze.crm_raw_user_acquisitions
ORDER BY status_acquisition_date;

-- > Cleaned column preview:
SELECT acquisition_date AS raw_acquisition_date,
        TRY_CONVERT(DATE,
        CASE 
            WHEN acquisition_date = 'invalid' THEN NULL
            --Checking for left to right format DD.MM.YYYY
            WHEN SUBSTRING(acquisition_date, 7, 4) IN ('2023', '2024') THEN '2024-' + SUBSTRING(acquisition_date, 4, 2) + '-' + SUBSTRING(acquisition_date,1,2)
            ELSE acquisition_date
        END) AS acquisition_date
FROM bronze.crm_raw_user_acquisitions


---------------------------------------------
-- 5) ACQUISITION CHANNEL TOUCH Quality Check
-- Detect messy or wrong data
---------------------------------------------
--Applying logic from cleaning channel column in touchpoints table
SELECT distinct acquisition_channel
FROM bronze.crm_raw_user_acquisitions
WHERE acquisition_channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)
ORDER BY acquisition_channel;

SELECT 
    acquisition_channel,
    COUNT(*) AS occurrences
FROM bronze.crm_raw_user_acquisitions
GROUP BY acquisition_channel
ORDER BY occurrences DESC;

-- > Cleaned column preview
SELECT
    acquisition_channel AS raw_acquisition_channel,
    CASE 
        WHEN acquisition_channel IS NULL OR acquisition_channel = '' THEN NULL
        WHEN lower(acquisition_channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
        WHEN lower(acquisition_channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
        WHEN lower(acquisition_channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
        WHEN lower(acquisition_channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
        WHEN lower(acquisition_channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
        WHEN lower(acquisition_channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
        WHEN lower(acquisition_channel) IN ('referal', 'referral') THEN 'Referral'
        WHEN lower(acquisition_channel) IN ('email') THEN 'Email'
        WHEN lower(acquisition_channel) IN ('direct') THEN 'Direct'
        ELSE acquisition_channel
    END AS acquisition_channel
FROM bronze.crm_raw_user_acquisitions


---------------------------------------------
-- 6) ACQUISITION CAMPAIGN Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning campaign id column in table ad spend
-- Comparing campaign ids with raw_campaigns table
SELECT distinct acquisition_campaign
FROM bronze.crm_raw_user_acquisitions
WHERE acquisition_campaign NOT IN(
    SELECT TRY_CONVERT(DECIMAL(10,2), campaign_id)
    FROM bronze.mrkt_raw_campaigns
)

SELECT
    acquisition_campaign,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) IS NULL THEN 'Non-numeric'
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) = 0 THEN 'Zero/invalid'
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) > 53 THEN 'Out of range (>53)'
        ELSE 'Valid'
    END AS id_status,
    COUNT(*) AS occurrences
FROM bronze.crm_raw_user_acquisitions
GROUP BY acquisition_campaign
ORDER BY id_status, acquisition_campaign;

-- > Cleaned column preview:
SELECT 
    acquisition_campaign AS raw_acquisition_campaign,
    TRY_CONVERT(INT,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) IS NULL THEN NULL
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) = 0 THEN NULL
        -- raw_campaigns shows IDs up to 53
        WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) > 53 THEN NULL
        ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), acquisition_campaign),0) 
    END) AS acquisition_campaign
FROM bronze.crm_raw_user_acquisitions


---------------------------------------------
-- 7) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.crm_raw_user_acquisitions
WHERE 
    (user_id IS NULL OR TRIM(user_id) = '')
 OR (acquisition_date IS NULL OR TRIM(acquisition_date) = '')
 OR (acquisition_channel IS NULL OR TRIM(acquisition_channel) = '')
 OR (acquisition_campaign IS NULL OR TRIM(acquisition_campaign) = '');
