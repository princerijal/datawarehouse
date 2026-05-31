/*
===============================================================================
Layer Transformation & Cleansing: Silver Layer
===============================================================================
Script Purpose:
    This script performs Data Quality (DQ) profiling, cleansing, and 
    transformation on raw data from 'bronze.crm_cust_info' and populates 
    the standardized 'silver.crm_cust_info' table.

Data Pipeline Stage:
    Bronze (Raw) -> Silver (Cleansed/Standardized)

Data Quality Issues Addressed:
    1. Duplicated Records: Resolved using ROW_NUMBER() window function.
    2. Missing/Null Keys: Filtered out invalid rows where 'cst_id' was NULL.
    3. Trailing/Leading Spaces: Resolved using the TRIM() function.
    4. Data Normalization: Standardized short codes for Marital Status and 
       Gender into fully readable text values with fallback 'N/A' handling.

Idempotency:
    The script includes a TRUNCATE statement making it safe for repeated execution.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Identity Duplicates & Null Keys
-- Expectation: No results (0 rows). If rows return, de-duplication logic is required.
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check 2: Unwanted Whitespaces in String Fields
-- Expectation: No results. If rows return, strings contain leading/trailing padding.
SELECT cst_firstName 
FROM bronze.crm_cust_info
WHERE TRIM(cst_firstName) <> cst_firstName;

-- Check 3: Categorical Consistency (Marital Status)
-- Expectation: See raw domain values to map (e.g., 'S', 'M', NULL)
SELECT DISTINCT cst_marital_status 
FROM bronze.crm_cust_info;

-- Check 4: Categorical Consistency (Gender)
-- Expectation: See raw domain values to map (e.g., 'F', 'M', NULL)
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;


-- ============================================================================
-- 2. SILVER LAYER TRANSFORMATION & LOAD
-- ============================================================================

-- Enforce script idempotency (ensures rerun safety without duplicating rows)
TRUNCATE TABLE silver.crm_cust_info;

-- Perform ETL into the Silver Target Table
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstName,
    cst_lastName,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    TRIM(cst_key) AS cst_key,          -- Clean whitespaces from keys
    TRIM(cst_firstName) AS cst_firstName,    -- Clean whitespaces from names
    TRIM(cst_lastName) AS cst_lastName,      -- Clean whitespaces from names
    
    -- Map short-codes to standardized categories
    CASE UPPER(TRIM(cst_marital_status))
        WHEN 'S' THEN 'Single'
        WHEN 'M' THEN 'Married'
        ELSE 'N/A'                     -- Handle NULL or unexpected values gracefully
    END AS cst_marital_status,
    
    -- Map short-codes to standardized categories
    CASE UPPER(TRIM(cst_gndr))
        WHEN 'F' THEN 'Female'
        WHEN 'M' THEN 'Male'
        ELSE 'N/A'                     -- Handle NULL or unexpected codes uniformly
    END AS cst_gndr,
    cst_create_date
FROM (
    -- Subquery utilizes a window function to isolate the latest record per customer ID
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL           -- Data Cleansing: Remove records missing primary business keys
) t 
WHERE flag_last = 1;                   -- Dedup Filtering: Keep only the latest record chunk


-- ============================================================================
-- 3. POST-TRANSLATION VALIDATION (Data Quality Auditing)
-- ============================================================================

-- Audit 1: Confirm all duplicate IDs and NULL keys have been successfully eliminated
-- Expected Result: Empty Set
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Audit 2: Validate that string values no longer possess leading/trailing spaces
-- Expected Result: Empty Set
SELECT cst_firstName 
FROM silver.crm_cust_info
WHERE TRIM(cst_firstName) <> cst_firstName;

-- Audit 3: Verify successful classification of domain values for Marital Status
-- Expected Result: 'Single', 'Married', 'N/A'
SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;

-- Audit 4: Verify successful classification of domain values for Gender
-- Expected Result: 'Male', 'Female', 'N/A'
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;
