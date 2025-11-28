/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/
USE marketing_dw;
GO
/*
===============================================================================
   marketing_platform tables
===============================================================================

Source: marketing_platform/raw_ad_spend.csv
Purpose: Stores raw ad spend from marketing channels.
Granularity: One row per channel per day.
*/
IF OBJECT_ID('bronze.mrkt_raw_ad_spend', 'U') IS NOT NULL
    DROP TABLE bronze.mrkt_raw_ad_spend;
GO

CREATE TABLE bronze.mrkt_raw_ad_spend (
    date            NVARCHAR(50),
    channel         NVARCHAR(100),
    campaign_id     NVARCHAR(50),
    spend           NVARCHAR(50) 
);
GO

/*
Source: marketing_platform/raw_campaigns.csv
Purpose: Stores raw campaign metadata from ad platforms.
Granularity: One row per campaign_id.
*/
IF OBJECT_ID('bronze.mrkt_raw_campaigns', 'U') IS NOT NULL
    DROP TABLE bronze.mrkt_raw_campaigns;
GO

CREATE TABLE bronze.mrkt_raw_campaigns (
    campaign_id     NVARCHAR(50),
    campaign_name   NVARCHAR(200),
    channel         NVARCHAR(100),
    start_date      NVARCHAR(50),
    end_date        NVARCHAR(50),
    objective       NVARCHAR(50)      
);
GO

/*
Source: marketing_platform/raw_clicks.csv
Purpose: Stores raw click events from ad platforms.
Granularity: One row per click_id.
*/
IF OBJECT_ID('bronze.mrkt_raw_clicks', 'U') IS NOT NULL
    DROP TABLE bronze.mrkt_raw_clicks;
GO

CREATE TABLE bronze.mrkt_raw_clicks (
    click_id        NVARCHAR(50),
    user_id         NVARCHAR(50),
    channel         NVARCHAR(100),
    campaign_id     NVARCHAR(50),
    timestamp       NVARCHAR(50)   
);
GO

/*
===============================================================================
   web_analytics tables
===============================================================================

Source: web_analytics/raw_sessions.csv
Purpose: Stores raw session metadata from web analytics.
Granularity: One row per session_id.
*/
IF OBJECT_ID('bronze.web_raw_sessions', 'U') IS NOT NULL
    DROP TABLE bronze.web_raw_sessions;
GO

CREATE TABLE bronze.web_raw_sessions (
    session_id      NVARCHAR(50),
    user_id         NVARCHAR(50),
    session_start   NVARCHAR(50),
    device          NVARCHAR(50),
    source_channel  NVARCHAR(100),
    pages_viewed    NVARCHAR(50)
);
GO

/*
Source: web_analytics/raw_touchpoints.csv
Purpose: Stores raw touchpoint events from web channels.
Granularity: One row per touchpoint event.
*/
IF OBJECT_ID('bronze.web_raw_touchpoints', 'U') IS NOT NULL
    DROP TABLE bronze.web_raw_touchpoints;
GO

CREATE TABLE bronze.web_raw_touchpoints (
    user_id         NVARCHAR(50),
    touchpoint_time NVARCHAR(50),
    channel         NVARCHAR(100),
    campaign_id     NVARCHAR(50),
    interaction_type NVARCHAR(50)
);
GO

/*
===============================================================================
   crm_system tables
===============================================================================

Source: crm_system/raw_channels.csv
Purpose: Stores raw channel_names with their category.
Granularity: One row per channel.
*/
IF OBJECT_ID('bronze.crm_raw_channels', 'U') IS NOT NULL
    DROP TABLE bronze.crm_raw_channels;
GO

CREATE TABLE bronze.crm_raw_channels (
    channel_name    NVARCHAR(50),
    category        NVARCHAR(50)
);
GO

/*
Source: crm_system/raw_purchases.csv
Purpose: Stores raw purchase metadata from the crm system.
Granularity: One row per purchase_id.
*/
IF OBJECT_ID('bronze.crm_raw_purchases', 'U') IS NOT NULL
    DROP TABLE bronze.crm_raw_purchases;
GO

CREATE TABLE bronze.crm_raw_purchases (
    purchase_id     NVARCHAR(50),
    user_id         NVARCHAR(50),
    purchase_date   NVARCHAR(50),
    revenue         NVARCHAR(50),
    channel_last_touch NVARCHAR(100)
);
GO

/*
Source: crm_system/raw_user_acquisitions.csv
Purpose: Stores acquisition metadata per user.
Granularity: One row per user_id.
*/
IF OBJECT_ID('bronze.crm_raw_user_acquisitions', 'U') IS NOT NULL
    DROP TABLE bronze.crm_raw_user_acquisitions;
GO

CREATE TABLE bronze.crm_raw_user_acquisitions (
    user_id         NVARCHAR(50),
    acquisition_date NVARCHAR(50),
    acquisition_channel NVARCHAR(100),
    acquisition_campaign NVARCHAR(50)
);
GO

