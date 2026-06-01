/*
===============================================================================
Database Object: gold.dim_customers (Dimensional Model View)
===============================================================================
Script Purpose:
    This script builds the primary customer dimension view 'gold.dim_customers'.
    It consolidates core profiles, demographics, and geographical fields from 
    disparate CRM and ERP source systems into a unified Star Schema entity.

Data Lineage:
    Silver Layer Inputs -> silver.crm_cust_info (Master Frame)
                        -> silver.erp_cust_az12 (Demographic Enrichment)
                        -> silver.erp_loc_a101  (Geographical Mapping)

Data Conflict Resolution Strategies:
    1. System Priority Rule: Gender conflicts are dynamically arbitrated by treating
       the CRM domain as the definitive master source, falling back to ERP 
       only when CRM yields 'n/a'.
    2. Surrogate Key Integration: Instantiates a virtual, non-volatile surrogate identity 
       key ('customer_key') to isolate the reporting layer from transactional IDs.
===============================================================================
*/

USE datawarehouse;
GO

-- Create Schema Container if it does not exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold;');
END
GO

-- Environment Reset Strategy: Re-deploy view model cleanly
DROP VIEW IF EXISTS gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id                             AS customer_id,
    ci.cst_key                            AS customer_number,
    ci.cst_firstname                      AS first_name,
    ci.cst_lastname                       AS last_name,
    la.cntry                              AS country,
    ci.cst_marital_status                 AS marital_status,
    CASE 
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr  -- Priority 1: Definitive CRM Master Entry
        ELSE COALESCE(ca.gen, 'n/a')                -- Priority 2: Fallback to ERP Domain
    END                                   AS gender,
    ca.bdate                              AS birth_date,
    ci.cst_create_date                    AS create_date		
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca 
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la 
    ON ci.cst_key = la.cid;
GO

-- ============================================================================
-- POST-DEPLOYMENT DATA QUALITY TESTING (Exception Check Validation Matrix)
-- ============================================================================

-- Audit 1: Surrogate Key Uniqueness and Completeness Check
-- Success Expectation: 0 Rows
SELECT customer_key, COUNT(*) 
FROM gold.dim_customers
GROUP BY customer_key 
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- Audit 2: Business Key Grain Integrity Check
-- Success Expectation: 0 Rows
SELECT customer_id, COUNT(*) 
FROM gold.dim_customers
GROUP BY customer_id 
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Audit 3: Gender Multi-Source Arbitration Cleanliness
-- Success Expectation: Only 'Male', 'Female', 'n/a' are allowed to emerge
SELECT DISTINCT gender FROM gold.dim_customers;
