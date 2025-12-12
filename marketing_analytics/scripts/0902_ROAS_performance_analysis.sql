/*
===============================================================================
ROAS Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of marketing components such as campagins and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) ROAS overall 
    2) ROAS Performance monthly
    3.1) Mid of Funnel (MOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    3.2) Top of Funnel (TOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    3.3) Bottom of Funnel (BOFU) Monthly ROAS Performance and MOM-Analysis by Campaigns
    3.4) Top Ten MOM Campaigns by TOFU/MOFU/BOFU 
    4.1) Mid of Funnel (MOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    4.2) Top of Funnel (TOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    4.3) Bottom of Funnel (BOFU) Monthly ROAS Performance and MOM-Analysis by Channels
    4.4) Top Ten MOM Channels by TOFU/MOFU/BOFU 

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) ROAS overall (120 days)
===============================================================================
*/ 
SELECT 
    (SELECT SUM(revenue) FROM gold.fact_purchases) AS revenue,
    (SELECT SUM(spend) FROM gold.fact_spend) AS spend,
    (SELECT SUM(revenue) FROM gold.fact_purchases)
    / 
    (Select SUM(spend) FROM gold.fact_spend) AS roas


/*
===============================================================================
2) ROAS Performance monthly
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.roas;
GO

CREATE VIEW gold.roas AS
WITH monthly_revenue AS (
    SELECT 
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        SUM(revenue) AS current_revenue 
    FROM gold.fact_purchases 
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
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month
)

SELECT 
    performance_year,
    performance_month,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER() AS avg_roas,
    (roas) - AVG(roas) OVER() AS diff_avg,
    CASE 
        WHEN (roas) - AVG(roas) OVER() > 0 THEN 'Above Avg'
        WHEN (roas) - AVG(roas) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(ORDER BY performance_year, performance_month) AS pm_roas, 
    (roas) - LAG(roas) OVER(ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN (roas) - LAG(roas) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (roas) - LAG(roas) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roas) - LAG(roas) OVER(ORDER BY performance_year, performance_month))/LAG(roas) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.roas
ORDER BY performance_year, performance_month;
GO
/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
--===================================
-- 3.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance of campaigns by comparing their ROAS to both the average ROAS performance of the campaign and the previous month ROAS 
DROP VIEW IF EXISTS gold.funnel_campaigns_roas;
GO

CREATE VIEW gold.funnel_campaigns_roas AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    SUM(f.revenue_share) AS current_revenue 
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
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.campaign_id, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.campaign_id = s.campaign_id

)

SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY campaign_id) AS avg_roas,
    (roas) - AVG(roas) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (roas) - AVG(roas) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (roas) - AVG(roas) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_roas, 
    (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((roas) - LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month))/LAG(roas) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.funnel_campaigns_roas
ORDER BY campaign_id, performance_year, performance_month;
GO

--=====================================
-- 3.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by acquisition campaign to see which campaigns are bringing users in
DROP VIEW IF EXISTS gold.acquisition_campaigns_roas;
GO

CREATE VIEW gold.acquisition_campaigns_roas AS
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
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.acquisition_campaign, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.acquisition_campaign = s.campaign_id

) 
SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_revenue,
    current_spend, 
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY acquisition_campaign) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   acquisition_campaign ORDER BY performance_year, performance_month))/LAG(roas) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.acquisition_campaigns_roas
ORDER BY acquisition_campaign, performance_year, performance_month;
GO

--==============================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by last-touch campaign to see which campaigns are driving conversion
DROP VIEW IF EXISTS gold.last_touch_campaigns_roas;
GO

CREATE VIEW gold.last_touch_campaigns_roas AS
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
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month,
    r.last_touch_campaign, 
    r.campaign_name,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.last_touch_campaign = s.campaign_id
)  

SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY last_touch_campaign) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month))/LAG(roas) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.last_touch_campaigns_roas
ORDER BY last_touch_campaign, performance_year, performance_month;


--==================================
-- 3.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM ROAS campaigns within funnel
SELECT TOP 10 *
FROM gold.funnel_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.funnel_campaigns_roas
WHERE pm_roas > 0 
ORDER BY mom_percentage DESC;

-- Top 10 MoM ROAS acquisition campaigns
SELECT TOP 10 *
FROM gold.acquisition_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.acquisition_campaigns_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM  ROAS last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_campaigns_roas
ORDER BY diff_pm_roas DESC; 

SELECT TOP 10 *
FROM gold.last_touch_campaigns_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
--===================================
-- 4.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance of channels by comparing their ROAS to both the average ROAS performance of the channel and the previous month ROAS 
DROP VIEW IF EXISTS gold.funnel_channels_roas;
GO

CREATE VIEW gold.funnel_channels_roas AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    channel, 
    SUM(revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), channel
),
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    COALESCE(r.channel, s.channel) AS channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.channel = s.channel
) 

SELECT 
    performance_year,
    performance_month,
    channel,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   channel ORDER BY performance_year, performance_month))/LAG(roas) OVER(PARTITION BY channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO

SELECT *
FROM gold.funnel_channels_roas
ORDER BY channel, performance_year, performance_month;
GO

--=====================================
-- 4.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues And Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by acquisition channel to see which channels are bringing users in
DROP VIEW IF EXISTS gold.acquisition_channels_roas;
GO

CREATE VIEW gold.acquisition_channels_roas AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    acquisition_channel, 
    SUM(revenue) AS current_revenue 
FROM gold.fact_purchases 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), acquisition_channel
),
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    r.acquisition_channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.acquisition_channel = s.channel
) 

SELECT 
    performance_year,
    performance_month,
    acquisition_channel,
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY acquisition_channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY   acquisition_channel ORDER BY performance_year, performance_month))/LAG(roas) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.acquisition_channels_roas
ORDER BY acquisition_channel, performance_year, performance_month;
GO


--==============================================
-- 4.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Ad Spend
-- Analyze Month-over-Month ROAS performance by last-touch channel to see which channels are driving conversion
DROP VIEW IF EXISTS gold.last_touch_channels_roas;
GO

CREATE VIEW gold.last_touch_channels_roas AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    last_touch_channel, 
    SUM(revenue) AS current_revenue 
FROM gold.fact_attribution_last_touch 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_channel
),
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
),
roas_metrics AS (
SELECT
    COALESCE(r.performance_year, s.performance_year) AS performance_year,
    COALESCE(r.performance_month, s.performance_month) AS performance_month, 
    r.last_touch_channel,
    r.current_revenue,
    s.current_spend,
    r.current_revenue/NULLIF(s.current_spend, 0) AS roas
FROM monthly_revenue r
FULL JOIN monthly_spend s 
ON r.performance_year = s.performance_year
    AND r.performance_month = s.performance_month 
    AND r.last_touch_channel = s.channel
) 

SELECT 
    performance_year,
    performance_month,
    last_touch_channel, 
    current_revenue,
    current_spend,
    roas AS current_roas,
    AVG(roas) OVER(PARTITION BY last_touch_channel) AS avg_roas,
    roas - AVG(roas) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN roas - AVG(roas) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_roas, 
    roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm_roas,
    CASE 
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (roas - LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year,performance_month))/LAG(roas) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM roas_metrics;
GO 

SELECT * 
FROM gold.last_touch_channels_roas
ORDER BY last_touch_channel, performance_year, performance_month;


--==================================
-- 4.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM channels within funnel
SELECT TOP 10 *
FROM gold.funnel_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.funnel_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM acquisition channels
SELECT TOP 10 *
FROM gold.acquisition_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.acquisition_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_roas
ORDER BY diff_pm_roas DESC;

SELECT TOP 10 *
FROM gold.last_touch_channels_roas
WHERE pm_roas > 0
ORDER BY mom_percentage DESC;

