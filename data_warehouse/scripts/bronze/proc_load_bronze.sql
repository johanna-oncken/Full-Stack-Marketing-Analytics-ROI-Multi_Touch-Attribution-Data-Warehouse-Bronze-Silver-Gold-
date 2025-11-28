/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the BULK INSERT command to load data into bronze tables.

Parameters:
    None. 
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
USE marketing_dw;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, 
            @end_time DATETIME, 
            @batch_start_time DATETIME, 
            @batch_end_time DATETIME, 
            @rows INT;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading MRKT Tables';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.mrkt_raw_ad_spend';
        TRUNCATE TABLE bronze.mrkt_raw_ad_spend;

        PRINT '>> Inserting Data INTO: bronze.mrkt_raw_ad_spend';
        BULK INSERT bronze.mrkt_raw_ad_spend
        FROM '/datasets/marketing_platform/raw_ad_spend.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.mrkt_raw_campaigns';
        TRUNCATE TABLE bronze.mrkt_raw_campaigns;

        PRINT '>> Inserting Data INTO: bronze.mrkt_raw_campaigns';
        BULK INSERT bronze.mrkt_raw_campaigns
        FROM '/datasets/marketing_platform/raw_campaigns.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();
        
        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.mrkt_raw_clicks';
        TRUNCATE TABLE bronze.mrkt_raw_clicks;

        PRINT '>> Inserting Data INTO: bronze.mrkt_raw_clicks';
        BULK INSERT bronze.mrkt_raw_clicks
        FROM '/datasets/marketing_platform/raw_clicks.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading WEB Tables';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.web_raw_sessions';
        TRUNCATE TABLE bronze.web_raw_sessions;

        PRINT '>> Inserting Data INTO: bronze.web_raw_sessions';
        BULK INSERT bronze.web_raw_sessions
        FROM '/datasets/web_analytics/raw_sessions.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.web_raw_touchpoints';
        TRUNCATE TABLE bronze.web_raw_touchpoints;

        PRINT '>> Inserting Data INTO: bronze.web_raw_touchpoints';
        BULK INSERT bronze.web_raw_touchpoints
        FROM '/datasets/web_analytics/raw_touchpoints.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_raw_channels';
        TRUNCATE TABLE bronze.crm_raw_channels;

        PRINT '>> Inserting Data INTO: bronze.crm_raw_channels';
        BULK INSERT bronze.crm_raw_channels
        FROM '/datasets/crm_system/raw_channels.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_raw_purchases';
        TRUNCATE TABLE bronze.crm_raw_purchases;

        PRINT '>> Inserting Data INTO: bronze.crm_raw_purchases';
        BULK INSERT bronze.crm_raw_purchases
        FROM '/datasets/crm_system/raw_purchases.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_raw_user_acquisitions';
        TRUNCATE TABLE bronze.crm_raw_user_acquisitions;

        PRINT '>> Inserting Data INTO: bronze.crm_raw_user_acquisitions';
        BULK INSERT bronze.crm_raw_user_acquisitions
        FROM '/datasets/crm_system/raw_user_acquisitions.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows Inserted: ' + CAST(@rows AS NVARCHAR);
        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';
    END TRY

    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
