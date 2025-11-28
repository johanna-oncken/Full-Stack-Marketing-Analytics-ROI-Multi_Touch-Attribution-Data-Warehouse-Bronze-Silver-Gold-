/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'marketing_dw' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'marketing_dw' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the Data Warehouse database named marketing_dw
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'marketing_dw')
BEGIN
    ALTER DATABASE marketing_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE marketing_dw;
END;
GO

-- Create the marketing_dw database
CREATE DATABASE marketing_dw;
GO

USE marketing_dw;
GO

-- Create Schemas
Create SCHEMA bronze;
GO

Create SCHEMA silver;
GO

Create SCHEMA gold;
GO
