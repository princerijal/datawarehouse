===============================================================================
-- DML Script: Load Silver Layer Table
-- Table: silver.crm_cust_info
-- Description: Cleanses, standardizes, and deduplicates customer data 
--              from the Bronze layer before inserting it into Silver.
===============================================================================

USE DataWarehouse;
GO

-- ===============================================================================
-- 1. PREPARATION
-- ===============================================================================
-- Truncate the Silver table to ensure a clean full-refresh load 
-- This prevents data duplication if the script is run multiple times.
TRUNCATE TABLE silver.crm_cust_info;
GO

-- ===============================================================================
-- 2. TRANSFORMATION AND LOAD
-- ===============================================================================
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
	-- Remove leading and trailing whitespaces from names
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname)  AS cst_lastname,
	
	-- Standardize Marital Status codes to readable full words
	CASE 
		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status,
	
	-- Standardize Gender codes to readable full words
	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM (
	-- Subquery: Deduplicate rows by identifying the latest record per customer
	SELECT *, 
		-- Assign a rank of 1 to the most recent record based on create date
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info 
	-- Data Quality Guardrail: Exclude records missing the Primary Key
	WHERE cst_id IS NOT NULL
) t 
-- Only load the latest active record per customer ID into the Silver layer
WHERE flag_last = 1;
GO
