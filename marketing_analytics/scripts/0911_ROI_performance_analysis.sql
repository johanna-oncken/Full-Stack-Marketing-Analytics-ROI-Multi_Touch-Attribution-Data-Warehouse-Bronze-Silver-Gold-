/*
===============================================================================
ROI Return on Investment Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the ROI performance in general and of marketing components such as campaigns and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) ROI overall (120 days)
    2) ROI Performance monthly
    3.1) ROI Performance by monthly Channel MOFU analysis
    3.2) ROI Performance by monthly Channel TOFU analysis 
    3.3) ROI Performance by monthly Channel BOFU analysis 
    4.1) ROI Performance by monthly Campaign MOFU analysis 
    4.2) ROI Performance by monthly Campaign TOFU analysis 
    4.3) ROI Performance by monthly Campaign BOFU analysis
===============================================================================
*/
USE marketing_dw; 
GO


/*
============================================================================== 
1) ROI overall
============================================================================== 
*/
SELECT 
    (SELECT SUM(revenue) FROM gold.fact_purchases) AS revenue,
    (SELECT SUM(spend) FROM gold.fact_spend) AS spend,
    ((SELECT SUM(revenue) FROM gold.fact_purchases)
    -
    (SELECT SUM(spend) FROM gold.fact_spend))
    / 
    (SELECT SUM(spend) FROM gold.fact_spend) AS ROI_120d;


/*
============================================================================== 
2) ROI Performance monthly
============================================================================== 
*/
DROP VIEW IF EXISTS gold.roi;
GO

CREATE VIEW gold.roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    SUM(revenue_share) AS current_revenue
FROM gold.fact_attribution_linear 
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY YEAR(spend_date), MONTH(spend_date)
), 
roi_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
)

SELECT 
    performance_year,
    performance_month,
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER() AS avg_roi,
    (roi) - AVG(roi) OVER() AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER() > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(ORDER BY performance_year, performance_month))/LAG(roi) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.roi
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) CHANNELS 
===============================================================================
3.1) Channels MOFU analysis
===============================================================================
*/
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI channel performance 
DROP VIEW IF EXISTS gold.channels_roi;
GO

CREATE VIEW gold.channels_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.channel, 
    SUM(revenue_share) AS current_revenue
FROM gold.fact_attribution_linear f
WHERE f.channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.channel
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE channel IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
), 
roi_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    COALESCE(r.channel, s.channel) AS channel, 
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    channel, 
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY channel) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.channels_roi
ORDER BY channel, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM ROI channels
SELECT TOP 10 *
FROM gold.channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM ROI channels
SELECT TOP 10 *
FROM gold.channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/

/*
===============================================================================
3.2) Channels TOFU analysis
===============================================================================
*/
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI acquisition channel performance 
DROP VIEW IF EXISTS gold.acquisition_channels_roi;
GO

CREATE VIEW gold.acquisition_channels_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.acquisition_channel, 
    SUM(revenue) AS current_revenue
FROM gold.fact_purchases f
WHERE f.acquisition_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.acquisition_channel
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE channel IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
), 
roi_metrics AS (
SELECT
    r.performance_year, 
    r.performance_month, 
    r.acquisition_channel, 
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.acquisition_channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    acquisition_channel, 
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY acquisition_channel) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.acquisition_channels_roi
ORDER BY acquisition_channel, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM ROI channels
SELECT TOP 10 *
FROM gold.acquisition_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.acquisition_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM ROI channels
SELECT TOP 10 *
FROM gold.acquisition_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.acquisition_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/

/*
===============================================================================
3.3) Channels BOFU analysis
===============================================================================
*/
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI last touch channel performance 
DROP VIEW IF EXISTS gold.last_touch_channels_roi;
GO

CREATE VIEW gold.last_touch_channels_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_channel, 
    SUM(revenue) AS current_revenue
FROM gold.fact_attribution_last_touch f
WHERE f.last_touch_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_channel
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE channel IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
), 
roi_metrics AS (
SELECT
    r.performance_year, 
    r.performance_month,
    r.last_touch_channel, 
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.last_touch_channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    last_touch_channel, 
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY last_touch_channel) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.last_touch_channels_roi
ORDER BY last_touch_channel, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM roi campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM roi campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/


/*
===============================================================================
4) CAMPAIGNS 
===============================================================================
4.1) Campaigns MOFU Analysis
===============================================================================
*/ 
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI campaign performance 
DROP VIEW IF EXISTS gold.campaigns_roi;
GO

CREATE VIEW gold.campaigns_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    SUM(revenue_share) AS current_revenue
FROM gold.fact_attribution_linear f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
WHERE f.campaign_id IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.campaign_id, c.campaign_name
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    campaign_id, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE campaign_id IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), campaign_id
), 
roi_metrics AS (
SELECT
    r.performance_year,
    r.performance_month,
    COALESCE(r.campaign_id, s.campaign_id) AS campaign_id, 
    r.campaign_name,
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.campaign_id = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY campaign_id) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_roi
ORDER BY campaign_id, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM ROI campaigns
SELECT TOP 10 *
FROM gold.campaigns_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.campaigns_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM ROI campaigns
SELECT TOP 10 *
FROM gold.campaigns_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.campaigns_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/


/*
===============================================================================
4.2) Campaigns TOFU analysis
===============================================================================
*/
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI acquisition campaign performance 
DROP VIEW IF EXISTS gold.acquisition_campaigns_roi;
GO

CREATE VIEW gold.acquisition_campaigns_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.acquisition_campaign, 
    c.campaign_name,
    SUM(revenue) AS current_revenue
FROM gold.fact_purchases f
LEFT JOIN gold.dim_campaign c 
ON f.acquisition_campaign = c.campaign_id
WHERE f.acquisition_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.acquisition_campaign, c.campaign_name
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    campaign_id, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE campaign_id IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), campaign_id
), 
roi_metrics AS (
SELECT
    r.performance_year, 
    r.performance_month, 
    r.acquisition_campaign, 
    r.campaign_name,
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.acquisition_campaign = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY acquisition_campaign) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.acquisition_campaigns_roi
ORDER BY acquisition_campaign, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM ROI campaigns
SELECT TOP 10 *
FROM gold.acquisition_campaigns_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.acquisition_campaigns_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM ROI campaigns
SELECT TOP 10 *
FROM gold.acquisition_campaigns_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.acquisition_campaigns_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/

/*
===============================================================================
4.3) Campaigns BOFU analysis
===============================================================================
*/
-- MoM by Monthly Revenue and Monthly Spend
-- Analyze Month-over-Month ROI last touch campaign performance 
DROP VIEW IF EXISTS gold.last_touch_campaigns_roi;
GO

CREATE VIEW gold.last_touch_campaigns_roi AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_campaign, 
    c.campaign_name,
    SUM(revenue) AS current_revenue
FROM gold.fact_attribution_last_touch f 
LEFT JOIN gold.dim_campaign c 
ON f.last_touch_campaign = c.campaign_id
WHERE f.last_touch_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_campaign, c.campaign_name
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    campaign_id, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE campaign_id IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), campaign_id
), 
roi_metrics AS (
SELECT
    r.performance_year, 
    r.performance_month,
    r.last_touch_campaign, 
    r.campaign_name,
    COALESCE(r.current_revenue, 0) - COALESCE(s.current_spend, 0) AS current_profit,
    s.current_spend,
    (r.current_revenue - s.current_spend)/NULLIF(s.current_spend, 0) AS roi
FROM monthly_revenue r
INNER JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.last_touch_campaign = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_profit,
    current_spend,
    roi AS current_roi,
    AVG(roi) OVER(PARTITION BY last_touch_campaign) AS avg_roi,
    (roi) - AVG(roi) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN (roi) - AVG(roi) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN (roi) - AVG(roi) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_roi, 
    (roi) - LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm_roi,
    CASE 
        WHEN (roi) - LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Higher'
        WHEN (roi) - LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Lower'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roi) - LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month))/LAG(roi) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roi_metrics
WHERE roi IS NOT NULL;
GO

SELECT *
FROM gold.last_touch_campaigns_roi
ORDER BY last_touch_campaign, performance_year, performance_month;
GO

/*
-- Top 10 Improvements MoM ROI campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi DESC; 

SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage DESC;

-- Top 10 Declines MoM ROI campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE diff_pm_roi IS NOT NULL
ORDER BY diff_pm_roi ASC; 

SELECT TOP 10 *
FROM gold.last_touch_channels_roi
WHERE pm_roi IS NOT NULL
ORDER BY mom_percentage ASC;
*/



