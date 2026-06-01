/*
===============================================================================
Layer Transformation, Cleansing & Testing: Silver Layer (Products)
===============================================================================
Script Purpose:
    This script contains the complete Data Quality (DQ) profiling framework, 
    cleansing transformations, and post-load validation audits for the 
    product dimension table 'silver.crm_prd_info'.

Data Pipeline Stage:
    Bronze (Raw) -> Silver (Cleansed/Standardized)

Data Quality Issues Addressed:
    1. Foreign Key Extraction: Derived 'cat_id' from composite business keys.
    2. Business Key Extraction: Shortened 'prd_key' to its core code format.
    3. Missing Metric Values: Defaulted missing product costs safely to 0.
    4. Categorical Consistency: Expanded short line codes to full textual domains.
    5. Historical Integrity: Overlapping timelines are resolved by re-building 
       active windows using LEAD(). Active records retain a NULL end-date.
===============================================================================
*/

USE datawarehouse;
GO

-- ============================================================================
-- 1. DATA QUALITY PROFILING (Pre-Transformation Checks)
-- ============================================================================

-- Check 1: Identity Duplications
-- Expectation: No result. If rows return, unique identifier constraints are violated.
SELECT prd_id, COUNT(*) 
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Check 2: Unwanted Whitespaces in Business Keys
-- Expectation: No Result.
SELECT prd_key 
FROM bronze.crm_prd_info
WHERE prd_key <> TRIM(prd_key);

-- Check 3: Unwanted Whitespaces in Product Names
-- Expectation: No Result.
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- Check 4: Check for Negative or Missing Product Costs
-- Expectation: No Results.
-- Output: Found 2 rows containing NULL values requiring default handling.
SELECT prd_cost 
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check 5: Categorical Consistency of Product Lines
-- Output: Null, M, R, S, T (Confirms clean single characters, mapping required)
SELECT DISTINCT prd_line 
FROM bronze.crm_prd_info;

-- Check 6: Timeline Integrity Verification
-- Output: Identified 200 rows with corrupted chronological sequence (prd_start_dt > prd_end_dt)
SELECT * FROM bronze.crm_prd_info
WHERE prd_start_dt IS NULL
   OR prd_start_dt > prd_end_dt;


-- ============================================================================
-- 2. SILVER LAYER TRANSFORMATION & LOAD
-- ============================================================================

-- Enforce script idempotency (rerun safety)
TRUNCATE TABLE silver.crm_prd_info;

-- Load cleaned and transformed data exactly as structured
INSERT INTO silver.crm_prd_info(
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
    -- Extract category ID prefix (e.g., 'AC-HE' -> 'AC_HE')
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    
    -- Extract clean product business key code
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    
    prd_nm,
    
    -- Default missing product costs to 0
    ISNULL(prd_cost, 0) AS prd_cost,
    
    -- Expand product line code abbreviations into full text descriptions
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    
    prd_start_dt,
    
    -- Recalculate historical timeline segments by shifting the next record's start date
    DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
FROM bronze.crm_prd_info;


-- ============================================================================
-- 3. POST-LOAD DATA QUALITY AUDITING (Validation Testing)
-- ============================================================================

-- Audit 1: Confirm data loading integrity and row structural uniqueness
-- Expected Result: No result
SELECT prd_id, COUNT(*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Audit 2: Validate whitespace mitigation for business keys
-- Expected Result: No result
SELECT prd_key 
FROM silver.crm_prd_info
WHERE prd_key <> TRIM(prd_key);

-- Audit 3: Validate whitespace mitigation for product names
-- Expected Result: No result
SELECT prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- Audit 4: Verify cost metric initialization rules applied successfully
-- Previous Output: 2 rows with null -> Final Output: No result
SELECT prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Audit 5: Verify successful expansion of domain descriptive categories
-- Previous Output: Null, M, R, S, T -> Final Output: Mountain, n/a, Other Sales, Road, Touring
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;

-- Audit 6: Confirm timeline sequencing updates resolved structural chronological errors
-- Previous Output: 200 rows with errors -> Final Output: 0 rows (Accounts for active NULL rows safely)
SELECT * FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL
   OR (prd_end_dt IS NOT NULL AND prd_start_dt > prd_end_dt);
