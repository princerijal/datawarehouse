===============================================================================
-- SQL Script: Data Quality Testing & Data Profiling (Bronze to Silver)
-- Source Table: bronze.crm_cust_info
-- Objective: Identify duplicates, nulls, formatting issues, and inconsistent 
--            categorical values before writing the Silver transformation logic.
===============================================================================

USE DataWarehouse;
GO

-- ===============================================================================
-- 1. General Data Preview
-- ===============================================================================
-- Quick visual check to understand the schema and look at sample data rows.
SELECT TOP 100 * FROM bronze.crm_cust_info;
GO


-- ===============================================================================
-- 2. Primary Key Integrity & Uniqueness Checks
-- ===============================================================================
-- Check for Nulls or Duplicates in the Primary Key (`cst_id`).
-- Expected Result: 0 rows returned. 
-- If rows appear, it indicates missing IDs or duplicate customer records.
SELECT 
    cst_id, 
    COUNT(*) AS record_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 
   OR cst_id IS NULL;
GO


-- ===============================================================================
-- 3. String Formatting & Whitespace Checks
-- ===============================================================================

-- Check for unwanted leading/trailing spaces in First Name.
-- Expected Result: 0 rows returned.
-- If rows appear, `TRIM()` is required during the Silver layer insertion.
SELECT cst_firstName 
FROM bronze.crm_cust_info
WHERE cst_firstName IS NULL 
   OR cst_firstName <> TRIM(cst_firstName);
GO

-- Check for unwanted leading/trailing spaces in Last Name.
-- Expected Result: 0 rows returned.
-- If rows appear, `TRIM()` is required during the Silver layer insertion.
SELECT cst_lastName 
FROM bronze.crm_cust_info
WHERE cst_lastName IS NULL 
   OR cst_lastName <> TRIM(cst_lastName);
GO


-- ===============================================================================
-- 4. Data Standardization & Categorical Consistency Checks
-- ===============================================================================

-- Profile Gender Column
-- Objective: Review all distinct variations of gender codes (e.g., 'M', 'F', 'Male', NULL, blanks).
-- This helps map out the `CASE WHEN` logic needed for Silver standardization.
SELECT DISTINCT 
    cst_gndr
FROM bronze.crm_cust_info;
GO

-- Profile Marital Status Column
-- Objective: Review all distinct variations of marital status codes (e.g., 'S', 'M', 'Single', 'Married').
-- This helps map out the `CASE WHEN` logic needed for Silver standardization.
SELECT DISTINCT 
    cst_marital_status
FROM bronze.crm_cust_info;
GO
