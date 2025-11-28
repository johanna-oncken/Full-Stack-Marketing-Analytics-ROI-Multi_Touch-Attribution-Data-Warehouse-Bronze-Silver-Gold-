/*===============================================================================
Data Profiling and Cleaning Script: Bronze Sessions
Purpose:
    This script profiles and cleans raw data from bronze.web_raw_sessions.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        session_id, user_id, session_start, device, source_channel, pages_viewed,
        COUNT(*) AS duplicates
    FROM bronze.web_raw_sessions
    GROUP BY session_id, user_id, session_start, device, source_channel, pages_viewed
    HAVING COUNT(*) > 1
)t;


---------------------------------------------
-- 3) ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT session_id 
FROM bronze.web_raw_sessions
GROUP BY session_id
HAVING COUNT(session_id) > 1;

SELECT session_id 
FROM bronze.web_raw_sessions
WHERE session_id IS NULL OR session_id = '';

-- > Cleaned column preview
SELECT session_id AS raw_session_id,
    TRY_CONVERT(INT, session_id) AS session_id
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 4) USER ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning user_id column in clicks table
-- Checking for unrealistic click counts
SELECT user_id, COUNT(user_id) 
FROM bronze.web_raw_sessions
GROUP BY user_id
HAVING COUNT(user_id) > 100;

-- Checking for missing user ids
SELECT user_id, COUNT(user_id)
FROM bronze.web_raw_sessions
WHERE user_id IS NULL
GROUP BY user_id;

-- Fine, because not all users are acquired
SELECT user_id 
FROM bronze.web_raw_sessions
WHERE user_id NOT IN (
    SELECT user_id 
    FROM bronze.crm_raw_user_acquisitions
);

-- > Cleaned column preview
SELECT user_id AS raw_user_id,
    TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 5) SESSION START Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning timestamp column in clicks table
-- Check if there is an unrealistic count of duplicate timestamps
SELECT DISTINCT session_start, COUNT(*)
FROM bronze.web_raw_sessions
GROUP BY session_start
HAVING COUNT(*) > 1;

SELECT 
    session_start,
    CASE
        WHEN session_start IS NULL THEN 'Missing'
        WHEN session_start = 'not_a_date' THEN 'Invalid'
        WHEN session_start LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
         AND LEN(session_start) = 16
            THEN 'Valid - DD/MM/YYYY HH:MM format'
        ELSE 'Valid - YYYY-MM-DD HH:MM:SS format'
    END AS status_session_start
FROM bronze.web_raw_sessions;

-- > Cleaned column preview
SELECT  
    session_start AS raw_session_start,
    TRY_CONVERT(DATETIME2,
    CASE 
        WHEN session_start IS NULL or session_start = 'not_a_date' THEN NULL
        WHEN session_start LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
            AND LEN(session_start) = 16
            THEN CONCAT(SUBSTRING(session_start, 7, 4), '-', SUBSTRING(session_start, 4, 2), '-', SUBSTRING(session_start, 1, 2), ' ', SUBSTRING(session_start, 12, 5), ':00')
        ELSE TRIM(session_start)
    END) AS session_start
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 6) DEVICE Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Small and easy overlook
SELECT DISTINCT device 
FROM bronze.web_raw_sessions;

SELECT 
    device,
    COUNT(*) AS occurrences 
 FROM bronze.web_raw_sessions
 GROUP BY device;

 SELECT 
    CASE 
        -- Categorizing into device categories: Mobile, Desktop, Table. Declaring OS 'Android' as Mobile because 90%+ of Android web/app traffic is phones
        WHEN device IS NULL THEN NULL
        WHEN LOWER(device) IN ('phone', 'android', 'mobile_web', 'iphone', 'mobile') 
            THEN 'Mobile'   
        WHEN LOWER(device) IN ('desktop', 'desk_top')
            THEN 'Desktop'
        WHEN LOWER(device) IN ('tablet', 'tab_let')
            THEN 'Tablet'
        ELSE device 
    END AS device 
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 7) SOURCE CHANNEL Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Modifying logic from cleaning channel columns in ad_spend and campaigns table
SELECT distinct source_channel   
FROM bronze.web_raw_sessions
WHERE source_channel NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)
ORDER BY source_channel;

SELECT 
    source_channel,
    COUNT(*) AS occurrences
FROM bronze.web_raw_sessions
GROUP BY source_channel
ORDER BY occurrences DESC;

-- > Cleaned column preview
SELECT
    source_channel AS raw_source_channel,
    CASE 
        WHEN lower(source_channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
        WHEN lower(source_channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
        WHEN lower(source_channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
        WHEN lower(source_channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
        WHEN lower(source_channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
        WHEN lower(source_channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
        WHEN lower(source_channel) IN ('referal', 'referral') THEN 'Referral'
        ELSE source_channel
    END AS source_channel
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 8) PAGES VIEWED Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT pages_viewed, COUNT(*) AS occurences
FROM bronze.web_raw_sessions
WHERE pages_viewed IS NULL 
  OR pages_viewed = ''
  OR LEN(pages_viewed) > 4
  OR LEN(pages_viewed) < 3
GROUP BY pages_viewed;
-- 832 missing values
SELECT TRY_CONVERT(DECIMAL(10,2), CAST(832 AS DECIMAL(10,2))/34208*100) AS percentage_missing_values

SELECT 
    pages_viewed,
    CASE 
        WHEN pages_viewed IS NULL THEN 'Missing'
        WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed) = 0 THEN 'Valid - Zero Views'
        WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed) = 1 THEN 'Valid - One Page'
        WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed)> 1 THEN 'Valid - Multi Page'
        ELSE 'Invalid'
    END AS status_pages_viewed,
    COUNT(*) AS OCCURENCES
FROM bronze.web_raw_sessions
GROUP BY pages_viewed,
        CASE 
            WHEN pages_viewed IS NULL THEN 'Missing'
            WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed) = 0 THEN 'Valid - Zero Views'
            WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed) = 1 THEN 'Valid - One Page'
            WHEN TRY_CONVERT(DECIMAL(10,1), pages_viewed)> 1 THEN 'Valid - Multi Page'
            ELSE 'Invalid'
        END   
ORDER BY status_pages_viewed

SELECT pages_viewed, COUNT(*) 
FROM bronze.web_raw_sessions
WHERE TRY_CONVERT(DECIMAL(10,1), pages_viewed) < 0
GROUP BY pages_viewed
-- 850 negative values "-1.0"
SELECT TRY_CONVERT(DECIMAL(10,2), CAST(850 AS DECIMAL(10,2))/34208*100) AS percentage_negative_ones


-- > Cleaned column preview
SELECT pages_viewed AS raw_pages_viewed,
    TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1),
    CASE 
        WHEN pages_viewed IS NULL THEN NULL 
        WHEN TRIM(pages_viewed) = '-1.0' THEN NULL
        ELSE pages_viewed
    END)) AS pages_viewed
FROM bronze.web_raw_sessions;


---------------------------------------------
-- 9) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.web_raw_sessions 
WHERE
    (session_id IS NULL OR TRIM(session_id) = '')
 OR (user_id IS NULL OR TRIM(user_id) = '')
 OR (session_start IS NULL OR TRIM(session_start) = '')
 OR (device IS NULL OR TRIM(device) = '')
 OR (source_channel IS NULL OR TRIM(source_channel) = '')
 OR (pages_viewed IS NULL OR TRIM(pages_viewed) = '');
