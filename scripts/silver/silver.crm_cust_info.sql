===============================================================================
-- DDL & DML Script: Silver Layer Table Creation & Load
-- Table: silver.crm_cust_info
-- Description: Creates, cleanses, loads, and verifies CRM customer data.
===============================================================================

USE DataWarehouse;
GO

-- ===============================================================================
-- 1. DROP & CREATE TABLE (DDL)
-- ===============================================================================
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
	cst_id             INT,
	cst_key            NVARCHAR(50),
	cst_firstname      VARCHAR(50),
	cst_lastname       VARCHAR(50),
	cst_marital_status VARCHAR(30),
	cst_gndr           VARCHAR(20),
	cst_create_date    DATE,
	dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO


-- ===============================================================================
-- 2. TRUNCATE & INSERT DATA (DML)
-- ===============================================================================
TRUNCATE TABLE silver.crm_cust_info;
GO

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
	TRIM(cst_lastname)  AS cst_lastname,
	CASE 
		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status,
	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM (
	SELECT *, 
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info 
	WHERE cst_id IS NOT NULL
) t 
WHERE flag_last = 1;
GO


-- ===============================================================================
-- 3. POST-CLEANSING DATA QUALITY CHECKS (QA)
-- ===============================================================================

-- Test 1: Check for Nulls or Duplicates in Primary Key
-- Expected Result: 0 rows
SELECT 
    cst_id, 
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;
GO

-- Test 2: Check for unwanted spaces in First Name
-- Expected Result: 0 rows
SELECT cst_firstname 
FROM silver.crm_cust_info
WHERE cst_firstname IS NULL 
   OR cst_firstname <> TRIM(cst_firstname);
GO

-- Test 3: Check for unwanted spaces in Last Name
-- Expected Result: 0 rows
SELECT cst_lastname 
FROM silver.crm_cust_info
WHERE cst_lastname IS NULL 
   OR cst_lastname <> TRIM(cst_lastname);
GO

-- Test 4: Verify Data Standardization (Gender)
-- Expected Result: Only 'Male', 'Female', or 'n/a'
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
GO

-- Test 5: Verify Data Standardization (Marital Status)
-- Expected Result: Only 'Single', 'Married', or 'n/a'
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;
GO
