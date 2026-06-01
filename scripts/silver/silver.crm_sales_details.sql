/*
===============================================================================
Layer Transformation, Cleansing & Testing: Silver Layer (Sales Transactions)
===============================================================================
Script Purpose:
    This script handles the Data Quality (DQ) profiling, cleansing transformations, 
    and transaction auditing for the fact data table 'silver.crm_sales_details'.

Data Pipeline Stage:
    Bronze (Raw) -> Silver (Cleansed/Standardized Fact)

Data Quality Issues Addressed:
    1. Integer Date Conversion: Parsed YYYYMMDD integers safely into real DATE types.
    2. Invalid Chronology Boundaries: Filtered out zero-dates and length mismatches.
    3. Financial Logic Realignment: Rebuilt sales metrics based on strict math boundaries 
       (Sales = Quantity * Price) using Absolute Values to eradicate negative metrics.
    4. Safe Division Management: Utilized NULLIF() to prevent system zero-division crashes.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Trailing or Leading Spaces in Core Keys
-- Expectation: No result
SELECT sls_ord_num FROM bronze.crm_sales_details WHERE sls_ord_num <> TRIM(sls_ord_num);
SELECT sls_prd_key FROM bronze.crm_sales_details WHERE sls_prd_key <> TRIM(sls_prd_key);

-- Check 2: Invalid Date Boundaries and Zero Values
-- Output: Identified anomalous zeros and chronological boundary violations
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt IS NULL 
   OR sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt 
   OR sls_order_dt <= 0;

-- Check 3: Raw Date Format Length Check
-- Output: Identified 19 rows with formatting length anomalies
SELECT sls_order_dt 
FROM bronze.crm_sales_details
WHERE LEN(sls_order_dt) <> 8 OR sls_order_dt > 20260601 OR sls_order_dt < 19000101;

-- Check 4: Transaction Math Inconsistencies (Sales vs. Volumetric Price Rules)
SELECT sls_sales, sls_quantity, sls_price 
FROM bronze.crm_sales_details 
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_quantity < 0
   OR sls_price < 0
   OR sls_sales IS NULL;


-- ============================================================================
-- 2. SILVER LAYER TRANSFORMATION & LOAD
-- ============================================================================

-- Enforce script idempotency (pipeline safety loop)
TRUNCATE TABLE silver.crm_sales_details;

-- Execute transactional load loop
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
    
    -- Parse integer fields safely into true SQL DATE objects
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
    
    -- Recalculate sales metrics to ensure math alignment (Quantity * Price)
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0 
        OR sls_sales <> sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    
    sls_quantity,
    
    -- FIXED: Used the explicit absolute calculation to eliminate dependencies on raw sales bugs
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0 THEN (sls_quantity * ABS(sls_price)) / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;


-- ============================================================================
-- 3. POST-LOAD DATA QUALITY AUDITING (Validation Testing)
-- ============================================================================

-- Audit 1: Check chronological integrity boundaries
-- Expected Result: 0 rows
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Audit 2: Verify fundamental equation alignment (Sales = Volume * Unit Cost)
-- Expected Result: 0 rows
SELECT sls_price, sls_quantity, sls_sales
FROM silver.crm_sales_details
WHERE sls_sales <> sls_price * sls_quantity;

-- Audit 3: Check for anomalous zeros, negative values, or hidden null metrics
-- Expected Result: 0 rows
SELECT sls_price, sls_quantity, sls_sales
FROM silver.crm_sales_details
WHERE sls_price <= 0 OR sls_quantity <= 0 OR sls_sales <= 0
   OR sls_price IS NULL OR sls_quantity IS NULL OR sls_sales IS NULL;
