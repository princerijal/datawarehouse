/*
===============================================================================
Database Schema, ETL Transformation & Testing: Silver Layer (ERP Location Data)
===============================================================================
Script Purpose:
    This comprehensive script handles the environment definition (DDL), 
    Data Quality (DQ) profiling, cleansing transformations, and geographical 
    standardization for the ERP location dataset 'silver.erp_loc_a101'.

Data Pipeline Stage:
    Bronze (Raw ERP Location) -> Silver (Cleansed/Standardized ERP Location)

Data Quality Issues Addressed:
    1. Structural Key Alignment: Stripped formatting hyphens ('-') out of the 
       customer ID ('cid') strings to properly reconcile with master CRM customer keys.
    2. Missing Geographic Data: Handled empty string and NULL values by defaulting 
       missing country records safely to 'n/a'.
    3. Categorical Standardization: Regularized a messy mixture of ISO country codes 
       ('DE', 'US', 'USA') and full-text names into consistent, clean full-text naming conventions.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Primary Key Uniqueness and Integrity
-- Expectation: No result
SELECT cid, COUNT(*) 
FROM bronze.erp_loc_a101
GROUP BY cid 
HAVING COUNT(*) > 1 OR cid IS NULL;

-- Check 2: Trailing or Leading Whitespaces
-- Expectation: No result
SELECT cid FROM bronze.erp_loc_a101 WHERE cid <> TRIM(cid);

-- Check 3: Raw Cross-System Integration Analysis
-- Note: Initially returned 0 matching records due to hidden string formatting hyphens
SELECT cid FROM bronze.erp_loc_a101
WHERE cid IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 4: Verification of Key Cleansing Logic
-- Expectation: No result (Confirms REPLACE function successfully resolves cross-system matching)
SELECT 
    REPLACE(cid, '-', '') AS replaced_id 
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 5: Identify Missing Geographic Metrics
-- Output: Revealed missing records alongside 5 completely blank strings
SELECT * FROM bronze.erp_loc_a101
WHERE cntry IS NULL OR cntry = '';

-- Check 6: Geographical Category Variations
-- Output: Mixed distinct entries (e.g., 'DE', 'Germany', 'US', 'USA', 'United States')
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;


-- ============================================================================
-- 2. ENVIRONMENT DEFINITION (DDL) & SILVER LAYER LOAD
-- ============================================================================

-- Environment Reset Strategy: Clean deployment to ensure repeatable execution
DROP TABLE IF EXISTS silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Execute geographical cleansing transformation pipeline
INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT 
    -- Strip out formatting hyphens to sync keys across separate system boundaries
    REPLACE(cid, '-', '') AS cid,

    -- Map abbreviation anomalies and handle missing data flags uniformly
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;


-- ============================================================================
-- 3. POST-LOAD DATA QUALITY AUDITING (Validation Testing)
-- ============================================================================

-- Audit 1: Exception Test for Cross-System Key Failures
-- Expected Result: 0 rows (Confirms absolute integrity matching with crm_cust_info)
SELECT cid FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Audit 2: Verify successful domain standardization rules
-- Expected Result: A distinct list of fully expanded country names, completely free of codes or blanks
SELECT DISTINCT cntry FROM silver.erp_loc_a101;
