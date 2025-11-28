/*===============================================================================
Data Profiling and Cleaning Script: Bronze Channels
Purpose:
    This script profiles and cleans raw data from bronze.crm_raw_channels.
===============================================================================*/
USE marketing_dw;
GO

---------------------------------------------
-- 1) Row Count
---------------------------------------------
SELECT COUNT(*) AS total_rows
FROM bronze.crm_raw_channels;


---------------------------------------------
-- 2) Note / Overlook
---------------------------------------------
SELECT channel_name, category
FROM bronze.crm_raw_channels;

-- Since this is a small table that shows an easy overlook, we can see that -- there are no wrong or empty spellings nor duplicates or other issues. No 
-- extra cleaning or profiling is needed.'
