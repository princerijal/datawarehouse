/*
=========================================================================================
PURPOSE:     Populate all tables created in the Bronze layer using BULK INSERT.
             Wrapped in a stored procedure for simple 1-line execution (EXEC bronze.load_bronze).
             Includes full truncation for clean full-refreshes, TRY...CATCH error handling, 
             and precise execution time tracking for every individual table.
WARNING:     Clears (truncates) existing data before executing the insert.
=========================================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    -- Prevent "(1 rows affected)" messages from cluttering the execution log
    SET NOCOUNT ON; 

    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start DATETIME = GETDATE();

    BEGIN TRY
        PRINT '=========================================================';
        PRINT '                     LOADING BRONZE LAYER                ';
        PRINT '=========================================================';

        ---------------------------------------------------------------------------------
        -- 1. CRM TABLES SECTION
        ---------------------------------------------------------------------------------
        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT ' LOADING CRM TABLES';
        PRINT '---------------------------------------------------------';

        -- Table 1: bronze.crm_cust_info
        PRINT ' >> Truncating and Loading: bronze.crm_cust_info';

        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_cust_info;
        
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\cust_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.crm_cust_info (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        PRINT '---------------------------------------------------------';

        -- Table 2: bronze.crm_prod_info
        PRINT ' >> Truncating and Loading: bronze.crm_prod_info';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_prod_info;
        
        BULK INSERT bronze.crm_prod_info
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\prd_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.crm_prod_info (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        PRINT '---------------------------------------------------------';

        -- Table 3: bronze.crm_sales_details
        PRINT ' >> Truncating and Loading: bronze.crm_sales_details';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_sales_details;
        
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\sales_details.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.crm_sales_details (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        
        PRINT '';
        PRINT ' -- CRM TABLES LOADING COMPLETED SUCCESSFULLY';
        PRINT '---------------------------------------------------------';


        ---------------------------------------------------------------------------------
        -- 2. ERP TABLES SECTION
        ---------------------------------------------------------------------------------
        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT ' LOADING ERP TABLES';
        PRINT '---------------------------------------------------------';

        -- Table 4: bronze.erp_cat_g1v2
        PRINT ' >> Truncating and Loading: bronze.erp_cat_g1v2';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_cat_g1v2;
        
        BULK INSERT bronze.erp_cat_g1v2
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\px_cat_g1v2.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.erp_cat_g1v2 (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        PRINT '---------------------------------------------------------';

        -- Table 5: bronze.erp_cust_az12
        PRINT ' >> Truncating and Loading: bronze.erp_cust_az12';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_cust_az12;
        
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\cust_az12.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.erp_cust_az12 (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        PRINT '---------------------------------------------------------';

        -- Table 6: bronze.erp_loc_a101
        PRINT ' >> Truncating and Loading: bronze.erp_loc_a101';
        SET @start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_loc_a101;
        
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\loc_a101.csv'
        WITH (FIRSTROW = 2,
        FIELDTERMINATOR = ',', 
        TABLOCK);
        
        SET @end_time = GETDATE();
        PRINT ' >> SUCCESS: Loaded bronze.erp_loc_a101 (' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' sec)';
        
        PRINT '';
        PRINT ' -- ERP TABLES LOADING COMPLETED SUCCESSFULLY';
        PRINT '---------------------------------------------------------';


        ---------------------------------------------------------------------------------
        -- SUMMARY SECTION
        ---------------------------------------------------------------------------------
        PRINT '';
        PRINT '=========================================================';
        PRINT ' SUCCESS: All Layers Loaded Successfully.';
        PRINT ' Total Batch Execution Time: ' + CAST(DATEDIFF(second, @batch_start, GETDATE()) AS VARCHAR(10)) + ' seconds.';
        PRINT '=========================================================';

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '=========================================================';
        PRINT ' ERROR OCCURRED TRYING TO LOAD BRONZE LAYER ';
        PRINT '=========================================================';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS VARCHAR(10));
        PRINT '=========================================================';
    END CATCH
END;
