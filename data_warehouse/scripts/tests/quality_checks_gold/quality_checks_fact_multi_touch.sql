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
-- Checking 'gold.fact_touchpath'
-- ====================================================================
SELECT TOP 10 * 
FROM gold.fact_touchpath

-- Check for uniqueness of touchpath_key ✅
-- Expected results: None
SELECT
    touchpath_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_touchpath
GROUP BY touchpath_key 
HAVING COUNT(*) > 1;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_touchpath
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);
 
-- Check consitency with dim_channel ✅
-- Expected results: None
SELECT *
FROM gold.fact_touchpath
WHERE channel NOT IN (
    SELECT channel_name
    FROM gold.dim_channel
);

-- Check consitency with dim_campaign ✅
-- Expected results: None
SELECT campaign_id
FROM gold.fact_touchpath
WHERE campaign_id IS NOT NULL AND campaign_id NOT IN (
    SELECT campaign_id
    FROM gold.dim_campaign
);

-- Check touchpoint sequence ✅
-- Expected results: None
SELECT *
FROM gold.fact_touchpath
WHERE touchpoint_number <= 0;

-- Check for NOT NULLs ✅
-- Expected results: None
SELECT * 
FROM gold.fact_touchpath
WHERE user_id IS NULL OR touchpoint_number IS NULL OR touchpoint_time IS NULL OR channel IS NULL OR interaction_type IS NULL;

-- Comparing row count with silver.web_touchpoint; Different tables, just for overview
-- 89,159 - 87,057
SELECT COUNT(*) AS row_count_touchpath,
   (SELECT COUNT(*) FROM gold.fact_touchpoints) AS row_count_touchpoints
FROM gold.fact_touchpath;

-- ====================================================================
-- Checking 'gold.fact_attribution_linear'
-- ====================================================================

SELECT TOP 10 *
FROM gold.fact_attribution_linear

-- Check for uniqueness of attribution_key ✅
-- Expected results: None
SELECT
    attribution_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_attribution_linear
GROUP BY attribution_key 
HAVING COUNT(*) > 1;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_attribution_linear
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);

-- Check consistency with fact_touchpath ✅
-- Expected results: None
SELECT *
FROM gold.fact_attribution_linear 
WHERE user_id NOT IN (
    SELECT user_id
    FROM gold.fact_touchpath
    WHERE purchase_id IS NOT NULL 
) OR purchase_id NOT IN (
    SELECT purchase_id 
    FROM gold.fact_touchpath
    WHERE purchase_id IS NOT NULL 
);

-- Check consistewncy with fact_purchaes ✅
-- Expected results: None
SELECT * 
FROM gold.fact_attribution_linear 
WHERE total_revenue NOT IN (
    SELECT revenue
    FROM gold.fact_purchases
) OR purchase_date NOT IN (
    SELECT purchase_date
    FROM gold.fact_purchases
);

-- Check revenue share sums correctily ✅
-- Expected results: None
-- Correct: allow rounding tolerance
SELECT purchase_id,
       SUM(revenue_share) AS total_share,
       MAX(total_revenue) AS expected,
       SUM(revenue_share) - MAX(total_revenue) AS diff
FROM gold.fact_attribution_linear
GROUP BY purchase_id
HAVING ABS(SUM(revenue_share) - MAX(total_revenue)) > 1.00;

-- Check for NOT NULLs ✅
-- Expected results: None 
SELECT * 
FROM gold.fact_attribution_linear
WHERE user_id IS NULL 
    OR purchase_id IS NULL
    OR channel IS NULL
    OR revenue_share IS NULL
    OR total_revenue IS NULL
    OR touchpoints_in_path IS NULL
    OR purchase_date IS NULL;

-- Comparing row count with gold.fact_touchpath and gold.fact_purchases; Different tables, just for overview
-- 13,814 - 89,159 - 3,531
SELECT COUNT(*) AS rows_linear,
   (SELECT COUNT(*) FROM gold.fact_touchpath) AS rows_touchpath,
   (SELECT COUNT(*) FROM gold.fact_purchases) AS rows_purchases
FROM gold.fact_attribution_linear;

-- ====================================================================
-- Checking 'gold.fact_attribution_last_touch'
-- ====================================================================
SELECT TOP 10 *
FROM gold.fact_attribution_last_touch;

-- Check for uniqueness of attribution_key ✅
-- Expected results: None
SELECT
    attribution_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_attribution_last_touch
GROUP BY attribution_key 
HAVING COUNT(*) > 1;

-- Check consistency with dim_user ✅
-- Expected results: None
SELECT user_id
FROM gold.fact_attribution_last_touch
WHERE user_id NOT IN (
    SELECT user_id FROM gold.dim_user
);
    
-- Check consistency with fact_touchpath ✅
-- Expected results: None
SELECT *
FROM gold.fact_attribution_last_touch
WHERE user_id NOT IN (
    SELECT user_id
    FROM gold.fact_touchpath
) OR purchase_id NOT IN (
    SELECT purchase_id 
    FROM gold.fact_touchpath
) OR last_touch_channel NOT IN (
    SELECT channel 
    FROM gold.fact_touchpath
) OR last_touch_campaign IS NOT NULL AND last_touch_campaign NOT IN (
    SELECT campaign_id 
    FROM gold.fact_touchpath
);

-- Check consistency with fact_purchases ✅ 
-- Expected results: None
SELECT *
FROM gold.fact_attribution_last_touch 
WHERE purchase_id NOT IN (SELECT purchase_id FROM gold.fact_purchases);

-- Check for NOT NULLs ✅
-- Expected results: None 
SELECT * 
FROM gold.fact_attribution_last_touch
WHERE user_id IS NULL
    OR purchase_id IS NULL
    OR last_touch_channel IS NULL
    OR revenue IS NULL
    OR purchase_date IS NULL

-- Comparing row count with gold.fact_touchpath; Different tables, just for overview
-- 2,656 - 89,159
SELECT COUNT(*) AS rows_last_touch,
   (SELECT COUNT(*) FROM gold.fact_touchpath) AS rows_touchpath
FROM gold.fact_attribution_last_touch;
