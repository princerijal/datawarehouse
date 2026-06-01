/*
===============================================================================
Database Schema, ETL Transformation & Testing: Silver Layer (ERP Product Category)
===============================================================================
Script Purpose:
    This comprehensive script handles the environment definition (DDL), 
    Data Quality (DQ) profiling, and ingestion loop for the ERP product 
    category lookups table 'silver.erp_px_cat_g1v2'.

Data Pipeline Stage:
    Bronze (Raw ERP Categories) -> Silver (Cleansed/Standardized ERP Categories)

Data Quality Issues Addressed:
    1. Integrity Auditing: Profiled unique constraints and cross-referenced keys.
       Source data was verified as structurally clean and free of trailing spaces, 
       requiring a pass-through structural loading strategy.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Primary Key Uniqueness and Null Auditing
-- Expectation: No result
SELECT id, COUNT(*)
FROM bronze.erp_px_cat_g1v2
GROUP BY id 
HAVING COUNT(*) > 1 OR id IS NULL;

-- Check 2: Integrity Mapping to Master Product Dimension
-- Expectation: No result (All category keys cleanly align with silver.crm_prd_info)
SELECT id 
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT DISTINCT cat_id FROM silver.crm_prd_info);

-- Check 3: Trailing or Leading Whitespace Auditing on Key Text Attributes
-- Expectation: No result
SELECT subcat 
FROM bronze.erp_px_cat_g1v2
WHERE subcat <> TRIM(subcat);

-- Check 4: Categorical Domain Boundaries (Category & Maintenance Attributes)
-- Output: Verified clean unique full-text descriptive records
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;


-- ============================================================================
-- 2. ENVIRONMENT DEFINITION (DDL) & SILVER LAYER LOAD
-- ============================================================================

-- Environment Reset Strategy: Clean deployment to ensure repeatable execution
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Execute direct ingestion pipeline (Pass-through for validated source table)
INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
SELECT 
    id, 
    cat, 
    subcat, 
    maintenance 
FROM bronze.erp_px_cat_g1v2;


-- ============================================================================
-- 3. POST-LOAD DATA QUALITY AUDITING (Validation Testing)
-- ============================================================================

-- Audit 1: Confirm successful record insertion and row counts
-- Expected Result: Table rows match the shape of the source bronze footprint perfectly
SELECT * FROM silver.erp_px_cat_g1v2;
