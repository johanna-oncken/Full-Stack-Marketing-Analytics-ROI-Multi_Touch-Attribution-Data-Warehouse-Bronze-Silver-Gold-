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
-- Checking 'gold.dim_date'
-- ====================================================================
SELECT TOP 10 *
FROM gold.dim_date;
--WHERE year > 2024 OR year < 2023;

-- Check for uniqueness of date_key ✅ 
-- Expected results: None
SELECT
    date_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_date
GROUP BY date_key 
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_user'
-- ====================================================================
SELECT TOP 10 *
FROM gold.dim_user;

-- Check for uniqueness of user_key ✅
-- Expected results: None
SELECT
    user_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_user
GROUP BY user_key 
HAVING COUNT(*) > 1;

-- Check for uniqueness of user_id ✅
-- Expected results: None
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_user
GROUP BY user_id
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_campaign'
-- ====================================================================
SELECT TOP 10 *
FROM gold.dim_campaign; 

-- Check for uniqueness of campaign_key ✅
-- Expected results: None
SELECT
    campaign_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_campaign
GROUP BY campaign_key 
HAVING COUNT(*) > 1;

-- Check for uniqueness of campaign_id ✅
-- Expected results: None
SELECT
    campaign_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_campaign
GROUP BY campaign_id
HAVING COUNT(*) > 1;

-- Check for consistent channels ✅
-- Expected results: Distinct, correctly written channel names
SELECT distinct channel
FROM gold.dim_campaign;
--WHERE channel != trim(channel) 

-- Check consistent campaign_name ✅
-- Expected results: None
SELECT 
    distinct campaign_name 
FROM gold.dim_campaign
WHERE campaign_name NOT IN (
    SELECT campaign_name
    FROM silver.mrkt_campaigns
);

-- Check row count ✅
-- Expected results: Equal counts 53 - 53
SELECT COUNT(*) AS gold_rows,
   (SELECT COUNT(*) FROM silver.mrkt_campaigns) AS silver_rows
FROM gold.dim_campaign

-- ====================================================================
-- Checking 'gold.dim_channel'
-- ====================================================================
SELECT *
FROM gold.dim_channel;

-- small table, unique channel key ✅
