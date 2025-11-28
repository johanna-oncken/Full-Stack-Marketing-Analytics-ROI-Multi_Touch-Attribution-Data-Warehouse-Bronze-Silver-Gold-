/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/
USE marketing_dw;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE 
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start_time DATETIME, 
        @batch_end_time DATETIME, 
        @rows INT;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading MRKT Tables';
        PRINT '------------------------------------------------';

        -- LOADING SILVER AD SPEND TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.mrkt_ad_spend';
        TRUNCATE TABLE silver.mrkt_ad_spend;
        PRINT '>> Inserting Data Into: silver.mrkt_ad_spend';
        INSERT INTO silver.mrkt_ad_spend (
            spend_date,
            channel,
            campaign_id,
            spend
        )
        SELECT DISTINCT --removing exact duplicate rows
                TRY_CONVERT(DATE,
                CASE 
                    WHEN date = 'not_available' THEN NULL
                    --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 dates
                    WHEN SUBSTRING(date, 7, 4) = '2024' THEN '2024-' + SUBSTRING(date, 4, 2) + '-' + SUBSTRING(date,1,2)
                    ELSE date
                END) AS spend_date,
                CASE 
                    WHEN channel IS NULL OR channel = '' THEN NULL
                    WHEN lower(channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                    WHEN lower(channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                    WHEN lower(channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                    WHEN lower(channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                    WHEN lower(channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                    WHEN lower(channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                    WHEN lower(channel) IN ('referal', 'referral') THEN 'Referral'
                    WHEN lower(channel) IN ('direct') THEN 'Direct'
                    WHEN lower(channel) IN ('email') THEN 'Email'
                    WHEN lower(channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                    WHEN lower(channel) IN ('programmatic display') THEN 'Programmatic Display'
                    WHEN lower(channel) IN ('sms') THEN 'SMS'
                    ELSE channel
                END AS channel,
                TRY_CONVERT(INT,
                CASE 
                    WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) IS NULL THEN NULL
                    WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) = 0 THEN NULL
                    -- raw_campaigns shows IDs up to 53
                    WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) > 53 THEN NULL
                    ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), campaign_id),0) 
                END) AS campaign_id,
                TRY_CONVERT(DECIMAL(10,2),
                TRIM(REPLACE(REPLACE(REPLACE((REPLACE(spend, 'USD', '')), '"', ''),'-', ''),',', '.'))) AS spend
        FROM bronze.mrkt_raw_ad_spend
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- LOADING SILVER CAMPAIGNS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.mrkt_campaigns';
        TRUNCATE TABLE silver.mrkt_campaigns;
        PRINT '>> Inserting Data Into: silver.mrkt_campaigns';
        INSERT INTO silver.mrkt_campaigns (
            campaign_id,
            campaign_name,
            channel,
            start_date,
            end_date,
            objective
        )
        SELECT 
            TRY_CONVERT(INT, campaign_id) AS campaign_id,
            CASE 
                --decided to rename some summer campaigns because of unrealtistic start dates and/or end dates
                WHEN (campaign_name = 'Summer_Launch' 
                    AND start_date = '2023-12-30') 
                OR (campaign_name = 'SUMMER_RETARGETING'
                    AND end_date = '2024-01-26')  
                    THEN 'New_Year_Launch'
                WHEN campaign_name = 'SUMMER_RETARGETING' 
                    AND end_date IN ('2024-03-30','2024-03-26')
                    THEN 'Brand_Awareness_Q1'
                WHEN campaign_name = 'SUMMER_RETARGETING' 
                    AND end_date NOT IN ('2024-03-30','2024-03-26')
                    THEN 'Summer_Retargeting'
                ELSE TRIM(campaign_name)
            END AS campaign_name,
            CASE 
                WHEN channel IS NULL OR channel = '' THEN NULL
                WHEN lower(channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(channel) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(channel) IN ('direct') THEN 'Direct'
                WHEN lower(channel) IN ('email') THEN 'Email'
                WHEN lower(channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(channel) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(channel) IN ('sms') THEN 'SMS'
                ELSE channel
            END AS channel,
            TRY_CONVERT(DATE,
            CASE 
                WHEN start_date = 'not_available' THEN NULL
                --Checking for left to right format DD.MM.YYYY
                WHEN SUBSTRING(start_date, 7, 4) IN ('2023', '2024') THEN SUBSTRING(start_date, 7, 4) + '-' + SUBSTRING(start_date, 4, 2) + '-' + SUBSTRING(start_date,1,2)
                ELSE start_date
            END) AS start_date,
            TRY_CONVERT(DATE,
            CASE 
                WHEN end_date = 'not_available' THEN NULL
                --Checking for left to right format DD.MM.YYYY
                WHEN SUBSTRING(end_date, 7, 4) IN ('2023', '2024') THEN SUBSTRING(end_date, 7, 4) + '-' + SUBSTRING(end_date, 4, 2) + '-' + SUBSTRING(end_date,1,2)
                ELSE end_date
            END) AS end_date,
            CASE 
                WHEN objective IS NULL THEN NULL
                WHEN TRIM(LOWER(objective)) LIKE 'aware%' THEN 'Awareness'
                WHEN TRIM(LOWER(objective)) LIKE 'conv%' THEN 'Conversion'
                WHEN TRIM(LOWER(objective)) = 'traffic' THEN 'Traffic'
                ELSE objective 
            END AS objective 
        FROM bronze.mrkt_raw_campaigns
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- LOADING SILVER CLICKS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.mrkt_clicks';
        TRUNCATE TABLE silver.mrkt_clicks;
        PRINT '>> Inserting Data Into: silver.mrkt_clicks';
        INSERT INTO silver.mrkt_clicks (
            click_id,
            user_id,
            channel,
            campaign_id,
            click_timestamp
        )
        SELECT
            TRY_CONVERT(INT, click_id) AS click_id,
            TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id,
            CASE 
                WHEN channel IS NULL OR channel = '' THEN NULL
                WHEN lower(channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(channel) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(channel) IN ('direct') THEN 'Direct'
                WHEN lower(channel) IN ('email') THEN 'Email'
                WHEN lower(channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(channel) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(channel) IN ('sms') THEN 'SMS'
                ELSE channel
            END AS channel,
            TRY_CONVERT(INT,
            CASE 
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) IS NULL THEN NULL
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) = 0 THEN NULL
                -- raw_campaigns shows IDs up to 53
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) > 53 THEN NULL
                ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), campaign_id),0) 
            END) AS campaign_id,
            TRY_CONVERT(DATETIME2(0),
            CASE 
                WHEN timestamp IS NULL or timestamp = 'invalid_date' THEN NULL
                WHEN timestamp LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
                    AND LEN(timestamp) = 16
                    THEN CONCAT(SUBSTRING(timestamp, 7, 4), '-', SUBSTRING(timestamp, 4, 2), '-', SUBSTRING(timestamp, 1, 2), ' ', SUBSTRING(timestamp, 12, 5), ':00')
                ELSE TRIM(timestamp)
            END) AS click_timestamp
        FROM bronze.mrkt_raw_clicks;
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading WEB Tables';
        PRINT '------------------------------------------------';
        -- LOADING SILVER SESSIONS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.web_sessions';
        TRUNCATE TABLE silver.web_sessions;
        PRINT '>> Inserting Data Into: silver.web_sessions';
        INSERT INTO silver.web_sessions (
            session_id,
            user_id,
            session_start,
            device,
            source_channel,
            pages_viewed
        )
        SELECT
            TRY_CONVERT(INT, session_id) AS session_id,
            TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id,
            TRY_CONVERT(DATETIME2(0),
            CASE 
                WHEN session_start IS NULL or session_start = 'not_a_date' THEN NULL
                WHEN session_start LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
                    AND LEN(session_start) = 16
                    THEN CONCAT(SUBSTRING(session_start, 7, 4), '-', SUBSTRING(session_start, 4, 2), '-', SUBSTRING(session_start, 1, 2), ' ', SUBSTRING(session_start, 12, 5), ':00')
                ELSE TRIM(session_start)
            END) AS session_start,
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
            END AS device,
            CASE 
                WHEN source_channel IS NULL OR source_channel = '' THEN NULL
                WHEN lower(source_channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(source_channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(source_channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(source_channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(source_channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(source_channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(source_channel) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(source_channel) IN ('direct') THEN 'Direct'
                WHEN lower(source_channel) IN ('email') THEN 'Email'
                WHEN lower(source_channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(source_channel) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(source_channel) IN ('sms') THEN 'SMS'
                ELSE source_channel
            END AS source_channel,
            TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1),
            CASE 
                WHEN pages_viewed IS NULL THEN NULL 
                WHEN TRIM(pages_viewed) = '-1.0' THEN NULL
                ELSE pages_viewed
            END)) AS pages_viewed
        FROM bronze.web_raw_sessions
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- LOADING SILVER TOUCHPOINTS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.web_touchpoints';
        TRUNCATE TABLE silver.web_touchpoints;
        PRINT '>> Inserting Data Into: silver.web_touchpoints';
        INSERT INTO silver.web_touchpoints (
            user_id,
            touchpoint_time,
            channel,
            campaign_id,
            interaction_type
        )
        SELECT
            DISTINCT --removing exact duplicate rows
            TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id,
            TRY_CONVERT(DATETIME2(3),
            CASE 
                WHEN touchpoint_time IS NULL or touchpoint_time = 'invalid' THEN NULL
                WHEN touchpoint_time LIKE '[0-3][0-9]/[0-1][0-9]/[1-2][0-9][0-9][0-9] [0-2][0-9]:[0-5][0-9]'
                    AND LEN(touchpoint_time) = 16
                    THEN CONCAT(SUBSTRING(touchpoint_time, 7, 4), '-', SUBSTRING(touchpoint_time, 4, 2), '-', SUBSTRING(touchpoint_time, 1, 2), ' ', SUBSTRING(touchpoint_time, 12, 5), ':00')
                ELSE TRIM(touchpoint_time)
            END) AS touchpoint_time,
            CASE 
                WHEN channel IS NULL OR channel = '' THEN NULL
                WHEN lower(channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(channel) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(channel) IN ('direct') THEN 'Direct'
                WHEN lower(channel) IN ('email') THEN 'Email'
                WHEN lower(channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(channel) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(channel) IN ('sms') THEN 'SMS'
                ELSE channel
            END AS channel,
            TRY_CONVERT(INT,
            CASE 
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) IS NULL THEN NULL
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) = 0 THEN NULL
                -- raw_campaigns shows IDs up to 53
                WHEN TRY_CONVERT(DECIMAL(10,1), campaign_id) > 53 THEN NULL
                ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), campaign_id),0) 
            END) AS campaign_id,
            CASE 
                WHEN interaction_type is NULL THEN NULL 
                WHEN LOWER(interaction_type) IN ('click', 'clik', 'clk') THEN 'Click'
                WHEN LOWER(interaction_type) IN ('impr', 'impression', 'impressions', 'Impression') THEN 'Impression'
                WHEN LOWER(interaction_type) IN ('page_view', 'view') THEN 'View' 
                ELSE interaction_type 
            END AS interaction_type
        FROM bronze.web_raw_touchpoints;
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';
        -- LOADING SILVER CHANNELS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_channels';
        TRUNCATE TABLE silver.crm_channels;
        PRINT '>> Inserting Data Into: silver.crm_channels';
        INSERT INTO silver.crm_channels (
            channel_name,
            category
        )
        SELECT channel_name, category
        FROM bronze.crm_raw_channels;
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- LOADING SILVER PURCHASES TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_purchases';
        TRUNCATE TABLE silver.crm_purchases;
        PRINT '>> Inserting Data Into: silver.crm_purchases';
        INSERT INTO silver.crm_purchases (
            purchase_id,
            user_id,
            purchase_date,
            revenue,
            channel_last_touch
        )
        SELECT 
            TRY_CONVERT(INT, purchase_id) AS purchase_id,
            TRY_CONVERT(INT, TRY_CONVERT( DECIMAL(10,1), user_id)) AS user_id,
            TRY_CONVERT(DATE,
                CASE 
                    WHEN purchase_date = 'invalid' THEN NULL
                    --Checking for left to right format DD.MM.YYYY, raw data only contains 2024 purchase_dates
                    WHEN SUBSTRING(purchase_date, 7, 4) = '2024' THEN '2024-' + SUBSTRING(purchase_date, 4, 2) + '-' + SUBSTRING(purchase_date,1,2)
                    ELSE purchase_date
                END) AS purchase_date,
            TRY_CONVERT(DECIMAL(10,2), revenue) AS revenue,
            CASE 
                WHEN channel_last_touch IS NULL OR channel_last_touch = '' THEN NULL
                WHEN lower(channel_last_touch) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(channel_last_touch) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(channel_last_touch) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(channel_last_touch) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(channel_last_touch) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(channel_last_touch) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(channel_last_touch) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(channel_last_touch) IN ('direct') THEN 'Direct'
                WHEN lower(channel_last_touch) IN ('email') THEN 'Email'
                WHEN lower(channel_last_touch) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(channel_last_touch) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(channel_last_touch) IN ('sms') THEN 'SMS'
                ELSE channel_last_touch
            END AS channel_last_touch
        FROM(
            SELECT purchase_id, user_id, purchase_date, revenue,
                TRIM(
                    CASE 
                        WHEN channel_last_touch LIKE '%,%' THEN SUBSTRING(channel_last_touch, CHARINDEX(',', channel_last_touch) + 1, LEN(channel_last_touch) - CHARINDEX(',', channel_last_touch))
                        ELSE channel_last_touch
                    END)AS channel_last_touch 
            FROM bronze.crm_raw_purchases)t;
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- LOADING SILVER USER ACQUISITIONS TABLE
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_user_acquisitions';
        TRUNCATE TABLE silver.crm_user_acquisitions;
        PRINT '>> Inserting Data Into: silver.crm_user_acquisitions';
        INSERT INTO silver.crm_user_acquisitions (
            user_id,
            acquisition_date,
            acquisition_channel,
            acquisition_campaign
        )
        SELECT
            TRY_CONVERT(INT, user_id) AS user_id,
            TRY_CONVERT(DATE,
            CASE 
                WHEN acquisition_date = 'invalid' THEN NULL
                --Checking for left to right format DD.MM.YYYY
                WHEN SUBSTRING(acquisition_date, 7, 4) IN ('2023', '2024') THEN '2024-' + SUBSTRING(acquisition_date, 4, 2) + '-' + SUBSTRING(acquisition_date,1,2)
                ELSE acquisition_date
            END) AS acquisition_date,
            CASE 
                WHEN acquisition_channel IS NULL OR acquisition_channel = '' THEN NULL
                WHEN lower(acquisition_channel) IN ('gogle search', 'google-search', 'googel search', 'google  search', 'google search') THEN 'Google Search'
                WHEN lower(acquisition_channel) IN ('googel display', 'google  display', 'google display') THEN 'Google Display'
                WHEN lower(acquisition_channel) IN ('fb ads', 'fb_ads', 'facebok ads', 'facebook ads') THEN 'Facebook Ads'
                WHEN lower(acquisition_channel) IN ('instgram ads', 'insta_ads', 'instagram ads') THEN 'Instagram Ads'
                WHEN lower(acquisition_channel) IN ('tik_tok_ads', 'tictok ads', 'tiktok ads') THEN 'TikTok Ads'
                WHEN lower(acquisition_channel) IN ('organic  search', 'organic_search', 'organic search') THEN 'Organic Search'
                WHEN lower(acquisition_channel) IN ('referal', 'referral') THEN 'Referral'
                WHEN lower(acquisition_channel) IN ('direct') THEN 'Direct'
                WHEN lower(acquisition_channel) IN ('email') THEN 'Email'
                WHEN lower(acquisition_channel) IN ('linkedin ads') THEN 'LinkedIn Ads'
                WHEN lower(acquisition_channel) IN ('programmatic display') THEN 'Programmatic Display'
                WHEN lower(acquisition_channel) IN ('sms') THEN 'SMS'
                ELSE acquisition_channel
            END AS acquisition_channel,
            TRY_CONVERT(INT,
            CASE 
                WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) IS NULL THEN NULL
                WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) = 0 THEN NULL
                -- raw_campaigns shows IDs up to 53
                WHEN TRY_CONVERT(DECIMAL(10,1), acquisition_campaign) > 53 THEN NULL
                ELSE ROUND(TRY_CONVERT(DECIMAL(10,1), acquisition_campaign),0) 
            END) AS acquisition_campaign
        FROM bronze.crm_raw_user_acquisitions;
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '=========================================='
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================='
    END TRY
    BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message ' + ERROR_MESSAGE();
		PRINT 'Error Message ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END

            
