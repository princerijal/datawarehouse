/*
===============================================================================
Data Quality Assurance & Testing Suite: Silver Layer
===============================================================================
Script Purpose:
    This diagnostic script serves as a centralized automated quality test suite 
    for validating the integrity, cleanliness, and cross-system alignment 
    of the Silver Layer datasets.

Testing Methodology:
    Every query in this script is designed as an "Exception Test" (or Assert Test). 
    A successful test run means the query must return ZERO rows. Any rows returned 
    indicate a data quality failure that requires pipeline troubleshooting.

File Location in Repository:
    /tests/silver_data_quality_tests.sql
===============================================================================
*/

USE datawarehouse;
GO

PRINT '=======================================================';
PRINT 'RUNNING SILVER LAYER EXCEPTION TESTING SUITE';
PRINT '=======================================================';

-- ============================================================================
-- 1. TESTING DIMENSION: silver.crm_cust_info
-- ============================================================================
PRINT '>> Testing Component: silver.crm_cust_info';

-- Test 1.1: Primary Key Uniqueness & Nullability
-- Expected Result: 0 Rows (Ensures deduplication logic functioned perfectly)
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Test 1.2: Leading/Trailing Whitespace Check on Keys
-- Expected Result: 0 Rows
SELECT cst_key FROM silver.crm_cust_info
WHERE UPPER(TRIM(cst_key)) <> UPPER(cst_key);

-- Test 1.3: Whitespace Check on Text Attributes (First Name)
-- Expected Result: 0 Rows
SELECT cst_firstname FROM silver.crm_cust_info
WHERE UPPER(cst_firstname) <> UPPER(TRIM(cst_firstname));

-- Test 1.4: Whitespace Check on Text Attributes (Last Name)
-- Expected Result: 0 Rows
SELECT cst_lastname FROM silver.crm_cust_info
WHERE UPPER(cst_lastname) <> UPPER(TRIM(cst_lastname));

-- Test 1.5: Marital Status Categorical Standardization Constraint
-- Expected Result: 0 Rows (Only 'Single', 'Married', or 'n/a' can exist)
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');

-- Test 1.6: Gender Categorical Standardization Constraint
-- Expected Result: 0 Rows (Only 'Male', 'Female', or 'n/a' can exist)
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'n/a');

PRINT '>> Component silver.crm_cust_info tests completed.';
PRINT '-------------------------------------------------------';


-- ============================================================================
-- 2. TESTING DIMENSION: silver.erp_cust_az12
-- ============================================================================
PRINT '>> Testing Component: silver.erp_cust_az12';

-- Test 2.1: Master Cross-System Foreign Key Alignment
-- Expected Result: 0 Rows (Verifies 'NAS' prefix removal completely fixed CRM connections)
SELECT cid FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Test 2.2: Chronological Birthday Boundary Check
-- Expected Result: 0 Rows (Ensures future birthdays were completely nullified)
SELECT bdate FROM silver.erp_cust_az12 
WHERE bdate > GETDATE();

-- Test 2.3: Unique Primary Key Verification
-- Expected Result: 0 Rows
SELECT cid, COUNT(*) FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;

-- Test 2.4: Gender Field Standardization Sync
-- Expected Result: 0 Rows (Only standardized domains allowed)
SELECT DISTINCT gen FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'n/a');

PRINT '>> Component silver.erp_cust_az12 tests completed.';
PRINT '-------------------------------------------------------';


-- ============================================================================
-- 3. TESTING DIMENSION: silver.erp_loc_a101
-- ============================================================================
PRINT '>> Testing Component: silver.erp_loc_a101';

-- Test 3.1: Master Cross-System Foreign Key Alignment
-- Expected Result: 0 Rows (Verifies hyphen replacement completely restored customer mapping)
SELECT cid FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Test 3.2: Country Field Domain Standardization Check
-- Expected Result: 0 Rows (Codes like 'US', 'DE', or blank fields must be 0)
SELECT DISTINCT cntry FROM silver.erp_loc_a101
WHERE cntry NOT IN ('Germany', 'United States', 'n/a');

PRINT '>> Component silver.erp_loc_a101 tests completed.';
PRINT '-------------------------------------------------------';


-- ============================================================================
-- 4. TESTING DIMENSION: silver.erp_px_cat_g1v2
-- ============================================================================
PRINT '>> Testing Component: silver.erp_px_cat_g1v2';

-- Test 4.1: Category Foreign Key Integrity
-- Expected Result: 0 Rows (Verifies references connect cleanly to Product table)
SELECT id FROM silver.erp_px_cat_g1v2
WHERE id NOT IN (SELECT DISTINCT cat_id FROM silver.crm_prd_info);

-- Test 4.2: Unique Category Row Check
-- Expected Result: 0 Rows
SELECT id, COUNT(*) FROM silver.erp_px_cat_g1v2
GROUP BY id 
HAVING COUNT(*) > 1 OR id IS NULL;

PRINT '>> Component silver.erp_px_cat_g1v2 tests completed.';
PRINT '-------------------------------------------------------';


-- ============================================================================
-- 5. TESTING FACT TABLE: silver.crm_sales_details
-- ============================================================================
PRINT '>> Testing Component: silver.crm_sales_details';

-- Test 5.1: Chronological Ordering Logic Guard
-- Expected Result: 0 Rows (An order cannot be shipped before it is placed)
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt;

-- Test 5.2: Mathematical Calculation Formula Verification
-- Expected Result: 0 Rows (Guarantees Total Sales equals Quantity x Price across all lines)
SELECT * FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price 
   OR sls_sales IS NULL 
   OR sls_sales <= 0;

-- Test 5.3: Zero-Quantity or Null Price Protection Guard
-- Expected Result: 0 Rows (Ensures division calculations did not create bad entries)
SELECT * FROM silver.crm_sales_details
WHERE sls_quantity IS NULL 
   OR sls_quantity < 0 
   OR sls_price IS NULL 
   OR sls_price <= 0;

PRINT '>> Component silver.crm_sales_details tests completed.';
PRINT '=======================================================';
PRINT 'SILVER LAYER DATA QUALITY TEST SUITE COMPLETED RUN';
PRINT '=======================================================';
