/*
===============================================================================
Stored Procedure: silver.load_silver (Master ETL Process)
===============================================================================
Script Purpose:
    This master stored procedure orchestrates, executes, and audits the entire 
    cleansing and transformation pipeline from the Bronze Layer staging tables
    into the clean, standardized Silver Layer core models.

Database Engineering Features:
    1. Idempotency: Executes individual table TRUNCATE blocks prior to loading, 
       guaranteeing repeatable executions without data duplication.
    2. Fault-Tolerant Logging: Entire architecture is wrapped within a unified 
       TRY...CATCH execution block to catch runtime errors immediately.
    3. Performance Instrumentation: Track step-by-step and total batch processing
       durations measured down to the millisecond.

Execution:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    SET NOCOUNT ON;
    
    -- Instrumentation Auditing Variables
    DECLARE @batch_start_time DATETIME2 = GETDATE();
    DECLARE @step_start_time  DATETIME2;
    DECLARE @step_end_time    DATETIME2;

    PRINT '=======================================================';
    PRINT 'STARTING SILVER LAYER PIPELINE ORCHESTRATION BATCH';
    PRINT 'Batch Start Timestamp: ' + CAST(@batch_start_time AS VARCHAR(30));
    PRINT '=======================================================';

    BEGIN TRY
        
        -- ====================================================================
        -- 1. LOAD DIMENSION: silver.crm_cust_info
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.crm_cust_info (Deduplication & Mapping)';
        
        TRUNCATE TABLE silver.crm_cust_info;
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE UPPER(TRIM(cst_marital_status))
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE UPPER(TRIM(cst_gndr))
                WHEN 'F' THEN 'Female'
                WHEN 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t 
        WHERE flag_last = 1;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.crm_cust_info | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '-------------------------------------------------------';


        -- ====================================================================
        -- 2. LOAD DIMENSION: silver.crm_prd_info
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.crm_prd_info (Timeline Adjustment)';

        TRUNCATE TABLE silver.crm_prd_info;
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            prd_start_dt,
            DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.crm_prd_info | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '-------------------------------------------------------';


        -- ====================================================================
        -- 3. LOAD DIMENSION: silver.erp_cust_az12
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.erp_cust_az12 (Key Alignment & Chronology)';

        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT 
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.erp_cust_az12 | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '-------------------------------------------------------';


        -- ====================================================================
        -- 4. LOAD DIMENSION: silver.erp_loc_a101
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.erp_loc_a101 (Geographical Normalization)';

        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.erp_loc_a101 | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '-------------------------------------------------------';


        -- ====================================================================
        -- 5. LOAD DIMENSION: silver.erp_px_cat_g1v2
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.erp_px_cat_g1v2 (Pass-Through Routing)';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance 
        FROM bronze.erp_px_cat_g1v2;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.erp_px_cat_g1v2 | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '-------------------------------------------------------';


        -- ====================================================================
        -- 6. LOAD CENTRAL FACT: silver.crm_sales_details
        -- ====================================================================
        SET @step_start_time = GETDATE();
        PRINT '>> Processing: silver.crm_sales_details (Financial Correction & Casting)';

        TRUNCATE TABLE silver.crm_sales_details;
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL 
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL 
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL 
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
            END AS sls_due_dt,
            CASE
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price) 
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0 
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS prd_price
        FROM bronze.crm_sales_details;

        SET @step_end_time = GETDATE();
        PRINT '>> Finished: silver.crm_sales_details | Duration: ' + CAST(DATEDIFF(millisecond, @step_start_time, @step_end_time) AS VARCHAR(10)) + ' ms';
        PRINT '=======================================================';

        -- Final Pipeline Metric Calculations
        DECLARE @batch_end_time DATETIME2 = GETDATE();
        PRINT 'SILVER LAYER CORE BATCH LOGGED SUCCESSFULLY';
        PRINT 'Total Cumulative Orchestration Runtime: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR(10)) + ' seconds';
        PRINT '=======================================================';

    END TRY
    BEGIN CATCH
        PRINT '=======================================================';
        PRINT '!!! PIPELINE FAILURE ENCOUNTERED IN SILVER TRANSACTION !!!';
        PRINT 'Error Profile Message: ' + ERROR_MESSAGE();
        PRINT 'Error Severity Code:   ' + CAST(ERROR_SEVERITY() AS VARCHAR(5));
        PRINT 'System State Code:     ' + CAST(ERROR_STATE() AS VARCHAR(5));
        PRINT '=======================================================';
        THROW;
    END CATCH
END;
GO
