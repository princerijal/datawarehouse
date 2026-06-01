/*
===============================================================================
Database Object: gold.dim_products (Dimensional Model View)
===============================================================================
Script Purpose:
    This script builds the primary product dimension view 'gold.dim_products'.
    It flattens the product profiles and category structures from the Silver 
    layer into a unified, non-normalized Star Schema dimension.

Data Lineage:
    Silver Layer Inputs -> silver.crm_prd_info  (Master Product Catalog)
                        -> silver.erp_px_cat_g1v2 (Category Lookup Mappings)

Data Filtering Strategies:
    1. SCD Type 2 Active Filter: Applies 'WHERE prd_end_dt IS NULL' to isolate 
       only currently active product versions, providing a clean grain for the 
       reporting layer.
    2. Surrogate Key Integration: Uses ROW_NUMBER() ordered by timeline attributes 
       to instantiate a unique, durable analytical key ('product_key').
===============================================================================
*/

USE datawarehouse;
GO

-- Environment Reset Strategy: Re-deploy view model cleanly
DROP VIEW IF EXISTS gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id                                               AS product_id,
    pn.prd_key                                              AS product_number,
    pn.prd_nm                                               AS product_name,
    pn.cat_id                                               AS category_id,
    pc.cat                                                  AS category,
    pc.subcat                                               AS sub_category,
    pc.maintenance                                          AS maintenance,
    pn.prd_cost                                             AS cost,
    pn.prd_line                                             AS product_line,
    pn.prd_start_dt                                         AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;
GO

-- ============================================================================
-- POST-DEPLOYMENT DATA QUALITY TESTING (Exception Check Validation Matrix)
-- ============================================================================

-- Audit 1: Surrogate Key Uniqueness and Completeness Check
-- Success Expectation: 0 Rows
SELECT product_key, COUNT(*) 
FROM gold.dim_products
GROUP BY product_key 
HAVING COUNT(*) > 1 OR product_key IS NULL;

-- Audit 2: Business Key Grain Integrity Check (No duplicate active products)
-- Success Expectation: 0 Rows
SELECT product_id, COUNT(*) 
FROM gold.dim_products
GROUP BY product_id 
HAVING COUNT(*) > 1 OR product_id IS NULL;

-- Audit 3: Financial Metric Boundary Guard
-- Success Expectation: 0 Rows
SELECT * FROM gold.dim_products 
WHERE cost < 0 OR cost IS NULL;

-- Audit 4: Chronological Timeline Guard
-- Success Expectation: 0 Rows
SELECT * FROM gold.dim_products 
WHERE start_date > GETDATE();

-- Audit 5: Domain Boundary Evaluation
-- Success Expectation: Verified distinct list of standardized categories and maintenance states
SELECT DISTINCT maintenance FROM gold.dim_products;
