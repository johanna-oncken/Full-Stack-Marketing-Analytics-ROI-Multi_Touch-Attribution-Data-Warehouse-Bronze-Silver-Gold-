/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'silver' tables.
===============================================================================
*/

USE marketing_dw;
GO
/*
===============================================================================
   marketing_platform tables
===============================================================================

Source: bronze.mrkt_raw_ad_spend
Purpose: Cleaned and standardized ad spend data.
Granularity: One row per channel per day.
*/
IF OBJECT_ID('silver.mrkt_ad_spend', 'U') IS NOT NULL
    DROP TABLE silver.mrkt_ad_spend;
GO

CREATE TABLE silver.mrkt_ad_spend (
    spend_date      DATE,
    channel         NVARCHAR(100),
    campaign_id     INT,
    spend           DECIMAL(10,2),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

/*
Source: bronze.mrkt_raw_campaigns
Purpose: Cleaned and standardized campaign metadata.
Granularity: One row per campaign_id.
*/
IF OBJECT_ID('silver.mrkt_campaigns', 'U') IS NOT NULL
    DROP TABLE silver.mrkt_campaigns;
GO

CREATE TABLE silver.mrkt_campaigns (
    campaign_id     INT,
    campaign_name   NVARCHAR(200),
    channel         NVARCHAR(100),
    start_date      DATE,
    end_date        DATE,
    objective       NVARCHAR(50), 
    dwh_create_date DATETIME2 DEFAULT GETDATE()
    
);
GO

/*
Source: bronze.mrkt_raw_clicks
Purpose: Cleaned and standardized click data.
Granularity: One row per click_id.
*/
IF OBJECT_ID('silver.mrkt_clicks', 'U') IS NOT NULL
    DROP TABLE silver.mrkt_clicks;
GO

CREATE TABLE silver.mrkt_clicks (
    click_id        INT,
    user_id         INT,
    channel         NVARCHAR(100),
    campaign_id     INT,
    click_timestamp       DATETIME2,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
   
);
GO

/*
===============================================================================
   web_analytics tables
===============================================================================

Source: bronze.web_raw_sessions
Purpose: Cleaned and standardized session metadata.
Granularity: One row per session_id.
*/
IF OBJECT_ID('silver.web_sessions', 'U') IS NOT NULL
    DROP TABLE silver.web_sessions;
GO

CREATE TABLE silver.web_sessions (
    session_id      INT,
    user_id         INT,
    session_start   DATETIME2,
    device          NVARCHAR(50),
    source_channel  NVARCHAR(100),
    pages_viewed    INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
 
);
GO

/*
Source: bronze.web_raw_touchpoints
Purpose: Cleaned and standardized touchpoint data.
Granularity: One row per touchpoint event.
*/
IF OBJECT_ID('silver.web_touchpoints', 'U') IS NOT NULL
    DROP TABLE silver.web_touchpoints;
GO

CREATE TABLE silver.web_touchpoints (
    user_id         INT,
    touchpoint_time DATETIME2,
    channel         NVARCHAR(100),
    campaign_id     INT,
    interaction_type NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
===============================================================================
   crm_system tables
===============================================================================

Source: bronze.crm_raw_channels
Purpose: Cleaned and standardized channel data.
Granularity: One row per channel.
*/
IF OBJECT_ID('silver.crm_channels', 'U') IS NOT NULL
    DROP TABLE silver.crm_channels;
GO

CREATE TABLE silver.crm_channels (
    channel_name    NVARCHAR(50),
    category        NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
Source: bronze.crm_raw_purchases
Purpose: Cleaned and standardized purchase metadata.
Granularity: One row per purchase_id.
*/
IF OBJECT_ID('silver.crm_purchases', 'U') IS NOT NULL
    DROP TABLE silver.crm_purchases;
GO

CREATE TABLE silver.crm_purchases (
    purchase_id     INT,
    user_id         INT,
    purchase_date   DATE,
    revenue         DECIMAL(10,2),
    channel_last_touch NVARCHAR(100),
    dwh_create_date DATETIME2 DEFAULT GETDATE()

);
GO

/*
Source: bronze.crm_raw_user_acquisitions
Purpose: Cleaned and standardized acquisition metadata.
Granularity: One row per user_id.
*/
IF OBJECT_ID('silver.crm_user_acquisitions', 'U') IS NOT NULL
    DROP TABLE silver.crm_user_acquisitions;
GO

CREATE TABLE silver.crm_user_acquisitions (
    user_id         INT,
    acquisition_date DATE,
    acquisition_channel NVARCHAR(100),
    acquisition_campaign INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()

);
GO

