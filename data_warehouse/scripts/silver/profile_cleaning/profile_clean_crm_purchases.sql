/*===============================================================================
Data Profiling and Cleaning Script: Bronze Purchases
Purpose:
    This script profiles and cleans raw data from bronze.crm_raw_purchases.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.crm_raw_purchases;



---------------------------------------------
-- 2) Duplicate Rows Check
---------------------------------------------
SELECT SUM(duplicates - 1) AS true_duplicate_rows
FROM (
    SELECT 
        purchase_id, user_id, purchase_date, revenue, channel_last_touch,
        COUNT(*) AS duplicates
    FROM bronze.crm_raw_purchases
    GROUP BY purchase_id, user_id, purchase_date, revenue, channel_last_touch
    HAVING COUNT(*) > 1
)t;


---------------------------------------------
-- 3) PURCHASE ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT purchase_id, COUNT(*)
FROM bronze.crm_raw_purchases
GROUP BY purchase_id
HAVING COUNT(*) > 1

SELECT purchase_id
FROM bronze.crm_raw_purchases
WHERE purchase_id IS NULL OR purchase_id = ''

-- > Cleaned column preview
SELECT 
    purchase_id AS raw_purchase_id,
    TRY_CONVERT(INT, purchase_id) AS purchase_id
FROM bronze.crm_raw_purchases;


---------------------------------------------
-- 4) USER ID Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Modifying logic from cleaning user_id column in touchpoints table
-- Checking for unrealistic user counts
SELECT user_id, COUNT(user_id) AS user_count
FROM bronze.crm_raw_purchases
GROUP BY user_id
HAVING COUNT(user_id) > 100; 

-- Checking for missing user ids
SELECT user_id, COUNT(user_id)
FROM bronze.crm_raw_purchases
WHERE user_id IS NULL OR user_id = ''
GROUP BY user_id;

-- about 97% of users with purchases do not appear in the acquisition table
SELECT COUNT(*) 
FROM bronze.crm_raw_purchases
WHERE user_id NOT IN (
    SELECT user_id 
    FROM bronze.crm_raw_user_acquisitions
)


-- > Cleaned column preview
SELECT user_id AS raw_user_id,
    TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id
FROM bronze.crm_raw_purchases;


---------------------------------------------
-- 5) PURCHASE DATE Quality Check
-- Detect messy or wrong data
---------------------------------------------
-- Applying logic from cleaning date column in ad spend table
SELECT purchase_date 
FROM bronze.crm_raw_purchases
WHERE LEN(purchase_date) != 10 

SELECT 
    DISTINCT purchase_date,
    CASE 
        WHEN purchase_date = 'invalid' THEN 'Missing'
        --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 purchase_dates
        WHEN SUBSTRING(purchase_date, 7, 4) = '2024' THEN 'DD.MM.YYYY format'
        WHEN TRY_CONVERT(DATE, purchase_date) IS NOT NULL THEN 'Valid'
        ELSE 'Invalid purchase_date Format'
    END AS status_purchase_date
FROM bronze.crm_raw_purchases
ORDER BY status_purchase_date;

-- > Cleaned column preview:
SELECT purchase_date AS raw_purchase_date,
        TRY_CONVERT(DATE,
        CASE 
            WHEN purchase_date = 'invalid' THEN NULL
            --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 purchase_dates
            WHEN SUBSTRING(purchase_date, 7, 4) = '2024' THEN '2024-' + SUBSTRING(purchase_date, 4, 2) + '-' + SUBSTRING(purchase_date,1,2)
            ELSE purchase_date
        END) AS purchase_date
FROM bronze.crm_raw_purchases


---------------------------------------------
-- 6) REVENUE Quality Check
-- Detect messy or wrong data
---------------------------------------------
SELECT revenue
FROM bronze.crm_raw_purchases
    WHERE revenue IS NULL OR revenue = ''
        OR TRY_CONVERT(DECIMAL(10,2), revenue) <= 0
        OR LEN(revenue) < 3 OR LEN(revenue) > 6

-- Checking count of negatives
SELECT count_negatives, 
    (SELECT ROUND(TRY_CONVERT(DECIMAL(10,2), 200)/3923*100,2)) AS percentage_negatives
FROM(
    SELECT COUNT(*) AS count_negatives
    FROM bronze.crm_raw_purchases
    WHERE TRY_CONVERT(DECIMAL(10,2), revenue) < 0)t

-- Check if negative revenues correspond to positive revenues
SELECT COUNT(*)
FROM bronze.crm_raw_purchases p
LEFT JOIN bronze.crm_raw_purchases r
    ON p.user_id = r.user_id
    AND TRY_CONVERT(DECIMAL(10,2), r.revenue) = 
        -TRY_CONVERT(DECIMAL(10,2), p.revenue)
WHERE TRY_CONVERT(DECIMAL(10,2), p.revenue) < 0;
-- -> Count of positives matches the count of negatives exactly. That is why they will be
-- => TREATING THEM AS RETURNS and keeping these negative numbers

SELECT revenue,
    CASE 
        WHEN revenue IS NULL OR revenue = '' THEN 'Missing'
        WHEN TRY_CONVERT(DECIMAL(10,2), revenue) < 0 THEN 'Valid - Return'
        WHEN TRY_CONVERT(DECIMAL(10,2), revenue) > 0 THEN 'Valid - Purchase'
        ELSE 'Valid'
    END AS status_revenue
FROM bronze.crm_raw_purchases

-- > Cleaned column preview:
SELECT revenue AS raw_revenue,
    TRY_CONVERT(DECIMAL(10,2), revenue) AS revenue
FROM bronze.crm_raw_purchases;


---------------------------------------------
-- 7) CHANNEL LAST TOUCH Quality Check
-- Detect messy or wrong data
---------------------------------------------
--Modyfying logic from cleaning channel column in touchpoints table
SELECT distinct channel_last_touch
FROM bronze.crm_raw_purchases
WHERE channel_last_touch NOT IN (
    SELECT channel_name
    FROM bronze.crm_raw_channels
)
ORDER BY channel_last_touch;

SELECT channel_last_touch
FROM bronze.crm_raw_purchases
WHERE channel_last_touch LIKE '%"%' OR channel_last_touch LIKE '%[0-9]"%'

SELECT 
    channel_last_touch,
    COUNT(*) AS occurrences
FROM bronze.crm_raw_purchases
GROUP BY channel_last_touch
ORDER BY occurrences DESC;

-- > Cleaned column preview
WITH clean_malformed AS (
    SELECT 
        channel_last_touch AS raw_channel_last_touch,
        TRIM(
        CASE 
            WHEN channel_last_touch LIKE '%,%' THEN SUBSTRING(channel_last_touch, CHARINDEX(',', channel_last_touch) + 1, LEN(channel_last_touch) - CHARINDEX(',', channel_last_touch))
            ELSE channel_last_touch
        END)AS channel_last_touch 
    FROM bronze.crm_raw_purchases
)

--SELECT DISTINCT channel_last_touch
--FROM(
SELECT
    raw_channel_last_touch,
    CASE 
        WHEN channel_last_touch IS NULL OR channel_last_touch = '' THEN NULL
        WHEN lower(channel_last_touch) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
        WHEN lower(channel_last_touch) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
        WHEN lower(channel_last_touch) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
        WHEN lower(channel_last_touch) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
        WHEN lower(channel_last_touch) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
        WHEN lower(channel_last_touch) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
        WHEN lower(channel_last_touch) IN ('referal', 'referral') THEN 'Referral'
        WHEN lower(channel_last_touch) IN ('email') THEN 'Email'
        WHEN lower(channel_last_touch) IN ('direct') THEN 'Direct'
        ELSE channel_last_touch
    END AS channel_last_touch
FROM clean_malformed
--)t


---------------------------------------------
-- 8) Empty or Null-Like Patterns
---------------------------------------------
SELECT *
FROM bronze.crm_raw_purchases
WHERE
    (purchase_id IS NULL OR TRIM(purchase_id) = '')
 OR (user_id IS NULL OR TRIM(user_id) = '')
 OR (purchase_date IS NULL OR TRIM(purchase_date) = '')
 OR (revenue IS NULL OR TRIM(revenue) = '')
 OR (channel_last_touch IS NULL OR TRIM(channel_last_touch) = '');
