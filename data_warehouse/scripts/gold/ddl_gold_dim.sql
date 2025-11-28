/*
===============================================================================
DDL Script: Create Gold Dim Tables
===============================================================================
Script Purpose:
    This script creates dim tables for the Gold layer in the marketing data 
    warehouse. 
    The Gold layer represents the final dimension and fact tables.

    Each table performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These gold tables can be queried directly for analytics and reporting.
===============================================================================
*/
USE marketing_dw;
GO
--=============================================================================
-- DIMENSION TABLES
--=============================================================================
--=============================================================================
-- Create Dimension: gold.dim_date
--=============================================================================
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO

CREATE TABLE gold.dim_date (
    date_key       INT           NOT NULL PRIMARY KEY, -- surrogate key (YYYYMMDD)
    full_date      DATE          NOT NULL,
    year           INT           NOT NULL,
    quarter        INT           NOT NULL,
    month          INT           NOT NULL,
    month_name     VARCHAR(50)   NOT NULL,
    week           INT           NOT NULL,
    day            INT           NOT NULL,
    day_name       VARCHAR(50)   NOT NULL,
    is_weekend     BIT           NOT NULL
);
GO

WITH DateSeries AS (
    SELECT CAST('2023-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM DateSeries
    WHERE dt < '2024-12-31'
)
INSERT INTO gold.dim_date (
    date_key, full_date, year, quarter, month, month_name,
    week, day, day_name, is_weekend
)
SELECT
    CONVERT(INT, FORMAT(dt, 'yyyyMMdd')) AS date_key,
    dt AS full_date,
    YEAR(dt) AS year,
    DATEPART(QUARTER, dt) AS quarter,
    MONTH(dt) AS month,
    DATENAME(MONTH, dt) AS month_name,
    DATEPART(WEEK, dt) AS week,
    DAY(dt) AS day,
    DATENAME(WEEKDAY, dt) AS day_name,
    CASE WHEN DATENAME(WEEKDAY, dt) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS is_weekend
FROM DateSeries
OPTION (MAXRECURSION 0); -- Stop recursion
GO


--============================================================================
-- Create Dimension: gold.dim_user
--============================================================================
IF OBJECT_ID('gold.dim_user', 'U') IS NOT NULL
    DROP TABLE gold.dim_user;
GO

CREATE TABLE gold.dim_user (
    user_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- surrogate Key
    user_id         INT               NOT NULL,              -- natural key 

    UNIQUE(user_id)                                          -- constraint
);

WITH unions AS (
    SELECT DISTINCT user_id
    FROM (
        SELECT user_id FROM silver.web_sessions
        UNION
        SELECT user_id FROM silver.mrkt_clicks
        UNION
        SELECT user_id FROM silver.web_touchpoints
        UNION
        SELECT user_id FROM silver.crm_purchases
        UNION
        SELECT user_id FROM silver.crm_user_acquisitions
    ) t
)
INSERT INTO gold.dim_user (user_id)
SELECT user_id
FROM unions
WHERE user_id IS NOT NULL
ORDER BY user_id;
GO
--============================================================================
-- Create Dimension: gold.dim_campaign
--============================================================================
IF OBJECT_ID('gold.dim_campaign', 'U') IS NOT NULL
    DROP TABLE gold.dim_campaign;
GO

CREATE TABLE gold.dim_campaign (
    campaign_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    campaign_id         INT               NOT NULL,-- natural key   
    campaign_name       NVARCHAR(100)     NULL,
    channel             NVARCHAR(50)      NOT NULL,
    start_date          DATE              NULL,
    end_date            DATE              NULL,
    objective           NVARCHAR(50)      NULL,

    UNIQUE(campaign_id)                           -- constraint
);
INSERT INTO gold.dim_campaign (
    campaign_id, campaign_name, channel, start_date, end_date, objective
)
SELECT 
    campaign_id,
    campaign_name,
    channel,
    start_date,
    end_date,
    objective
FROM silver.mrkt_campaigns;
GO
--============================================================================
-- Create Dimension: gold.dim_channel
--============================================================================
IF OBJECT_ID('gold.dim_channel', 'U') IS NOT NULL
    DROP TABLE gold.dim_channel 
GO 

CREATE TABLE gold.dim_channel (
    channel_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    channel_name    NVARCHAR(50)      NOT NULL,
    category        NVARCHAR(50)      NOT NULL,

    UNIQUE(channel_name)              -- constraint
);
INSERT INTO gold.dim_channel (
    channel_name, category
)
SELECT 
    channel_name,
    category 
FROM silver.crm_channels;
GO
