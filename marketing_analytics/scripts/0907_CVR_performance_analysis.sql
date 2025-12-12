/*
===============================================================================
CVR Conversion Rate Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CVR performance of marketing components such as campaigns and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) CVR overall 
    2) CVR Performance monthly 
    3.1) MOFU CVR (Clicks -> Conversions) by Channel
    3.2) TOFU CVR (Impressions -> Clicks) by Channel (Please read disclaimer)
    3.3) BOFU CVR (Clicks -> Last-Touch Conversions) by Channel 
    4.1) MOFU CVR (Clicks -> Conversions) by Campaign
    4.2) TOFU CVR (Impressions -> Clicks) by Campaign (Please read disclaimer)
    4.3) BOFU CVR (Clicks -> Last-Touch Conversions) by Campaign 

===============================================================================
*/
USE marketing_dw; 
GO 


/*
===============================================================================
1) CVR overall
===============================================================================
*/ 
SELECT 
    (SELECT COUNT(distinct purchase_id) FROM gold.fact_purchases) AS conversions,
    (SELECT COUNT(click_id) FROM gold.fact_clicks) AS clicks,
    (SELECT COUNT(distinct purchase_id) FROM gold.fact_purchases) * 1.0
    / 
    (SELECT COUNT(click_id) FROM gold.fact_clicks) AS cvr;


/*
===============================================================================
2) CVR Performance monthly (Clicks -> Conversions)
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.cvr;
GO

CREATE VIEW gold.cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(click_timestamp) AS performance_year,
        MONTH(click_timestamp) AS performance_month,
        COUNT(*) AS clicks
    FROM gold.fact_clicks
    GROUP BY YEAR(click_timestamp), MONTH(click_timestamp)
),
monthly_conversions AS (
    SELECT
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        COUNT(DISTINCT purchase_id) AS conversions
    FROM gold.fact_purchases
    GROUP BY YEAR(purchase_date), MONTH(purchase_date)
),
cvr_metrics AS (
    SELECT
        COALESCE(cl.performance_year, co.performance_year) AS performance_year,
        COALESCE(cl.performance_month, co.performance_month) AS performance_month,
        cl.clicks AS current_clicks,
        COALESCE(co.conversions, 0) AS current_conversions,
        COALESCE(co.conversions,0) * 1.0 / NULLIF(cl.clicks,0) AS cvr
    FROM monthly_clicks cl
    LEFT JOIN monthly_conversions co
        ON cl.performance_year = co.performance_year
        AND cl.performance_month = co.performance_month
)

SELECT 
    performance_year,
    performance_month,
    current_clicks,
    current_conversions,
    cvr AS current_cvr,
    AVG(cvr) OVER() AS avg_cvr,
    (cvr) - AVG(cvr) OVER() AS diff_avg,
    CASE 
        WHEN (cvr) - AVG(cvr) OVER() > 0 THEN 'Above Avg'
        WHEN (cvr) - AVG(cvr) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cvr) OVER(ORDER BY performance_year, performance_month) AS pm_cvr, 
    (cvr) - LAG(cvr) OVER(ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN (cvr) - LAG(cvr) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Improved'
        WHEN (cvr) - LAG(cvr) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cvr) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cvr) - LAG(cvr) OVER(ORDER BY performance_year, performance_month))/LAG(cvr) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cvr_metrics;
GO

SELECT *
FROM gold.cvr
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) Channels
===============================================================================
3.1) MOFU CVR (Clicks -> Conversions) by Channel
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.channels_cvr;
GO

CREATE VIEW gold.channels_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(click_timestamp) AS performance_year,
        MONTH(click_timestamp) AS performance_month,
        click_channel,
        COUNT(*) AS clicks
    FROM gold.fact_clicks
    WHERE click_channel IS NOT NULL
    GROUP BY YEAR(click_timestamp), MONTH(click_timestamp), click_channel
),
monthly_conversions AS (
    SELECT
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        channel,
        COUNT(DISTINCT purchase_id) AS conversions
    FROM gold.fact_attribution_linear
    WHERE channel IS NOT NULL
    GROUP BY YEAR(purchase_date), MONTH(purchase_date), channel
),
cvr_metrics AS (
    SELECT
        cl.performance_year,
        cl.performance_month,
        cl.click_channel AS channel,
        cl.clicks AS current_clicks,
        COALESCE(co.conversions, 0) AS current_conversions,
        COALESCE(co.conversions, 0) * 1.0 / NULLIF(cl.clicks, 0) AS cvr
    FROM monthly_clicks cl
    LEFT JOIN monthly_conversions co
        ON cl.performance_year = co.performance_year
        AND cl.performance_month = co.performance_month
        AND cl.click_channel = co.channel
)

SELECT
    performance_year,
    performance_month,
    channel,
    current_clicks,
    current_conversions,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY channel) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY channel) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY channel) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY channel) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change,
    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cvr
ORDER BY channel, performance_year, performance_month;
GO


/*
===============================================================================
3.2) TOFU CVR (Impressions -> Clicks) by Channel
===============================================================================
        !! Disclaimer                                           !!
        Due to synthetic data the clicks are about four times
        higher than impressions. Therefor TOFU CVR should be 
        interpreted with caution.
*/ 
DROP VIEW IF EXISTS gold.channels_tofu_cvr;
GO

CREATE VIEW gold.channels_tofu_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(click_timestamp) AS performance_year,
        MONTH(click_timestamp) AS performance_month,
        click_channel,
        COUNT(*) AS clicks
    FROM gold.fact_clicks
    WHERE click_channel IS NOT NULL
    GROUP BY YEAR(click_timestamp), MONTH(click_timestamp), click_channel
),
monthly_impressions AS (
    SELECT
        YEAR(touchpoint_time) AS performance_year,
        MONTH(touchpoint_time) AS performance_month,
        channel,
        COUNT(*) AS impressions
    FROM gold.fact_touchpoints 
    WHERE interaction_type = 'Impression'
    GROUP BY YEAR(touchpoint_time), MONTH(touchpoint_time), channel
),
cvr_metrics AS (
    SELECT
        c.performance_year,
        c.performance_month,
        c.click_channel AS channel,
        COALESCE(c.clicks, 0) AS current_clicks,
        COALESCE(i.impressions, 0) AS current_impressions,
        COALESCE(c.clicks, 0) * 1.0 / NULLIF(i.impressions, 0) AS cvr
    FROM monthly_impressions i
    LEFT JOIN monthly_clicks c
        ON c.performance_year = i.performance_year
        AND c.performance_month = i.performance_month
        AND c.click_channel = i.channel
)

SELECT
    performance_year,
    performance_month,
    channel,
    current_impressions,
    current_clicks,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY channel) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY channel) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY channel) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY channel) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change, 

    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_tofu_cvr
ORDER BY channel, performance_year, performance_month;
GO


/*
===============================================================================
3.3) BOFU CVR (Clicks -> Last-Touch Conversions) by Channel
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.channels_bofu_cvr;
GO

CREATE VIEW gold.channels_bofu_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(click_timestamp) AS performance_year,
        MONTH(click_timestamp) AS performance_month,
        click_channel,
        COUNT(*) AS clicks
    FROM gold.fact_clicks
    WHERE click_channel IS NOT NULL
    GROUP BY YEAR(click_timestamp), MONTH(click_timestamp), click_channel
),
monthly_conversions AS (
    SELECT
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        last_touch_channel,
        COUNT(DISTINCT purchase_id) AS conversions
    FROM gold.fact_attribution_last_touch
    GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_channel
),
cvr_metrics AS (
    SELECT
        c.performance_year,
        c.performance_month,
        c.click_channel AS channel,
        COALESCE(c.clicks, 0) AS current_clicks,
        COALESCE(co.conversions, 0) AS current_conversions,
        COALESCE(co.conversions, 0) * 1.0 / NULLIF(c.clicks, 0) AS cvr
    FROM monthly_clicks c
    LEFT JOIN monthly_conversions co
        ON c.performance_year = co.performance_year
        AND c.performance_month = co.performance_month
        AND c.click_channel = co.last_touch_channel
)

SELECT
    performance_year,
    performance_month,
    channel,
    current_clicks,
    current_conversions,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY channel) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY channel) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY channel) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY channel) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change, 
    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY channel ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_bofu_cvr
ORDER BY channel, performance_year, performance_month;
GO



/*
===============================================================================
4) Campaigns
===============================================================================
4.1) MOFU CVR (Clicks -> Conversions) by Campaign
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.campaigns_cvr;
GO

CREATE VIEW gold.campaigns_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(f.click_timestamp) AS performance_year,
        MONTH(f.click_timestamp) AS performance_month,
        f.campaign_id,
        c.campaign_name,
        COUNT(*) AS clicks
    FROM gold.fact_clicks f 
    LEFT JOIN gold.dim_campaign c 
    ON f.campaign_id = c.campaign_id
    WHERE f.campaign_id IS NOT NULL
    GROUP BY YEAR(f.click_timestamp), MONTH(f.click_timestamp), f.campaign_id, c.campaign_name
),
monthly_conversions AS (
    SELECT
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        campaign_id,
        COUNT(DISTINCT purchase_id) AS conversions
    FROM gold.fact_attribution_linear
    WHERE campaign_id IS NOT NULL
    GROUP BY YEAR(purchase_date), MONTH(purchase_date), campaign_id
),
cvr_metrics AS (
    SELECT
        cl.performance_year,
        cl.performance_month,
        cl.campaign_id, 
        cl.campaign_name,
        cl.clicks AS current_clicks,
        COALESCE(co.conversions, 0) AS current_conversions,
        COALESCE(co.conversions, 0) * 1.0 / NULLIF(cl.clicks, 0) AS cvr
    FROM monthly_clicks cl 
    LEFT JOIN monthly_conversions co
        ON cl.performance_year = co.performance_year
        AND cl.performance_month = co.performance_month
        AND cl.campaign_id = co.campaign_id
)

SELECT
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_clicks,
    current_conversions,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY campaign_id) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY campaign_id) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change,
    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cvr
ORDER BY campaign_id, performance_year, performance_month;
GO



/*
===============================================================================
4.2) TOFU CVR (Impressions -> Clicks) by Campaign
===============================================================================
        !! Disclaimer                                           !!
        Due to synthetic data the clicks are about three times
        higher than impressions. Therefor TOFU CVR should be 
        interpreted with caution.
*/ 
DROP VIEW IF EXISTS gold.campaigns_tofu_cvr;
GO

CREATE VIEW gold.campaigns_tofu_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(click_timestamp) AS performance_year,
        MONTH(click_timestamp) AS performance_month,
        campaign_id,
        COUNT(*) AS clicks
    FROM gold.fact_clicks
    WHERE campaign_id IS NOT NULL
    GROUP BY YEAR(click_timestamp), MONTH(click_timestamp), campaign_id
),
monthly_impressions AS (
    SELECT
        YEAR(touchpoint_time) AS performance_year,
        MONTH(touchpoint_time) AS performance_month,
        campaign_id,
        COUNT(*) AS impressions
    FROM gold.fact_touchpoints 
    WHERE interaction_type = 'Impression'
    GROUP BY YEAR(touchpoint_time), MONTH(touchpoint_time), campaign_id
),
cvr_metrics AS (
    SELECT
        c.performance_year,
        c.performance_month,
        c.campaign_id AS campaign_id,
        COALESCE(c.clicks, 0) AS current_clicks,
        COALESCE(i.impressions, 0) AS current_impressions,
        COALESCE(c.clicks, 0) * 1.0 / NULLIF(i.impressions, 0) AS cvr
    FROM monthly_impressions i
    LEFT JOIN monthly_clicks c
        ON c.performance_year = i.performance_year
        AND c.performance_month = i.performance_month
        AND c.campaign_id = i.campaign_id
)

SELECT
    performance_year,
    performance_month,
    campaign_id,
    current_impressions,
    current_clicks,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY campaign_id) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY campaign_id) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change, 

    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_tofu_cvr
ORDER BY campaign_id, performance_year, performance_month;
GO



/*
===============================================================================
4.3) BOFU CVR (Clicks -> Last-Touch Conversions) by Campaign
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.campaigns_bofu_cvr;
GO

CREATE VIEW gold.campaigns_bofu_cvr AS
WITH monthly_clicks AS (
    SELECT
        YEAR(f.click_timestamp) AS performance_year,
        MONTH(f.click_timestamp) AS performance_month,
        f.campaign_id,
        c.campaign_name,
        COUNT(*) AS clicks
    FROM gold.fact_clicks f
    LEFT JOIN gold.dim_campaign c 
    ON f.campaign_id = c.campaign_id
    WHERE f.campaign_id IS NOT NULL
    GROUP BY YEAR(f.click_timestamp), MONTH(f.click_timestamp), f.campaign_id, c.campaign_name
),
monthly_conversions AS (
    SELECT
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        last_touch_campaign,
        COUNT(DISTINCT purchase_id) AS conversions
    FROM gold.fact_attribution_last_touch
    GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_campaign
),
cvr_metrics AS (
    SELECT
        c.performance_year,
        c.performance_month,
        c.campaign_id, 
        c.campaign_name,
        COALESCE(c.clicks, 0) AS current_clicks,
        COALESCE(co.conversions, 0) AS current_conversions,
        COALESCE(co.conversions, 0) * 1.0 / NULLIF(c.clicks, 0) AS cvr
    FROM monthly_clicks c
    LEFT JOIN monthly_conversions co
        ON c.performance_year = co.performance_year
        AND c.performance_month = co.performance_month
        AND c.campaign_id = co.last_touch_campaign
)

SELECT
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_clicks,
    current_conversions,
    cvr AS current_cvr,
    AVG(cvr) OVER (PARTITION BY campaign_id) AS avg_cvr,
    cvr - AVG(cvr) OVER (PARTITION BY campaign_id) AS diff_avg,
    CASE
        WHEN cvr > AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Above Avg'
        WHEN cvr < AVG(cvr) OVER (PARTITION BY campaign_id) THEN 'Below Avg'
        ELSE 'Equals Avg'
    END AS avg_change, 
    -- Month-over_Month analysis
    LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_cvr,
    cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_cvr,
    CASE 
        WHEN cvr > LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Improved'
        WHEN cvr < LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) THEN 'Declined'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE
            WHEN LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL
            ELSE (
                (cvr - LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)) /
                LAG(cvr) OVER (PARTITION BY campaign_id ORDER BY performance_year, performance_month)
            ) * 100
        END, 2
    ) AS mom_percentage
FROM cvr_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_bofu_cvr
ORDER BY campaign_id, performance_year, performance_month;
GO







