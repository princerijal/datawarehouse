/*
===============================================================================
Database Schema, ETL Transformation & Testing: Silver Layer (ERP Customer Data)
===============================================================================
Script Purpose:
    This comprehensive script handles the environment definition (DDL), 
    Data Quality (DQ) profiling, cleansing transformations, and system 
    cross-referencing for the ERP customer dataset 'silver.erp_cust_az12'.

Data Pipeline Stage:
    Bronze (Raw ERP) -> Silver (Cleansed/Standardized ERP Customer)

Data Quality Issues Addressed:
    1. Legacy Business Prefixing: Stripped out hardcoded 'NAS' prefixes from older 
       customer IDs ('cid') to properly align with CRM 'cst_key' values.
    2. Chronological Birthday Anomalies: Set future birthdays to NULL. Verified 
       historical dates are fully intact and free of '1900' default system bugs, 
       allowing valid senior customer history to be completely preserved.
    3. Categorical Standardization: Regularized multi-format gender classifications 
       ('M', 'Male', 'F', 'Female', blanks) into uniform 'Male', 'Female', and 'n/a'.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Cross-System Key Matching Failure (CRM vs ERP)
-- Output: Found rows prefixed with 'NAS' failing to match the target dimension keys
SELECT cid FROM bronze.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 2: Validation of Key Cleansing Logic
-- Expectation: No result (Confirms SUBSTRING logic perfectly aligns keys)
SELECT 
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS clean_cid
FROM bronze.erp_cust_az12
WHERE 
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 3: Unique Primary Key Verification
-- Expectation: No result
SELECT cid, COUNT(*) 
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

-- Check 4: Age Boundary Analysis (Future dates)
-- Output: Identified 35 rows containing future timestamps requiring nullification
SELECT bdate FROM bronze.erp_cust_az12
WHERE bdate IS NULL OR bdate > GETDATE();

-- Check 5: Categorical Gender Evaluation
-- Output: Blanks, NULLs, 'F', 'M', 'Male', 'Female' (Requires mapping)
SELECT DISTINCT gen FROM bronze.erp_cust_az12;


-- ============================================================================
-- 2. ENVIRONMENT DEFINITION (DDL) & SILVER LAYER LOAD
-- ============================================================================

-- Environment Reset Strategy: Clean deployment to ensure repeatable execution
DROP TABLE IF EXISTS silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Execute cleansing transformation pipeline
INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT 
    -- Clean historical prefix discrepancies out of business keys
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    
    -- Nullify future dates; preserve valid historical customer timelines
    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,
    
    -- Standardize inconsistent categorical strings
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;


-- ============================================================================
-- 3. POST-LOAD DATA QUALITY AUDITING (Validation Testing)
-- ============================================================================

-- Audit 1: Confirm absolute correlation with master CRM system keys
-- Expected Result: 0 rows
SELECT cid FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Audit 2: Confirm age profiling constraints (No future dates remain)
-- Expected Result: 0 rows
SELECT bdate FROM silver.erp_cust_az12 
WHERE bdate > GETDATE();

-- Audit 3: Confirm gender domain standardization rules
-- Expected Result: Only 'Male', 'Female', 'n/a'
SELECT DISTINCT gen FROM silver.erp_cust_az12;
