/*
===============================================================================
Database Object: gold.fact_sales (Fact Model View)
===============================================================================
Script Purpose:
    This script builds the central fact table view 'gold.fact_sales'.
    It acts as the core transactional nucleus of the Star Schema, resolving
    business transactions and linking dimensions together via surrogate keys.

Data Lineage:
    Silver Layer Inputs -> silver.crm_sales_details (Central Transactions Ledger)
    Gold Layer Inputs   -> gold.dim_products       (Product Reference Domain)
                        -> gold.dim_customers      (Customer Reference Domain)

Data Modeling Principles:
    1. Surrogate Key Substitution: Strips away volatile upstream business keys
       and maps transactions directly to analytical integer keys.
    2. Zero Information Loss: Retains primary transaction granular numbers
       and tracking dates for time-series modeling.
===============================================================================
*/

USE datawarehouse;
GO

-- Environment Reset Strategy: Re-deploy view model cleanly
DROP VIEW IF EXISTS gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num   AS order_number,
    pr.product_key   AS product_key,
    cu.customer_key  AS customer_key,
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO

-- ============================================================================
-- POST-DEPLOYMENT DATA QUALITY TESTING (Exception Check Validation Matrix)
-- ============================================================================

-- Audit 1: Referential Integrity Check against Customer Dimension
-- Success Expectation: 0 Rows (Confirms no orphan sales exist without a valid customer profile)
SELECT * FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Audit 2: Referential Integrity Check against Product Dimension
-- Success Expectation: 0 Rows (Confirms no sales are mapped to missing or invalid products)
SELECT * FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key 
WHERE p.product_key IS NULL;

-- Audit 3: Column Metrics Completeness Check
-- Success Expectation: 0 Rows (Ensures key financial indicators are fully populated)
SELECT * FROM gold.fact_sales 
WHERE sales_amount IS NULL OR quantity IS NULL OR price IS NULL;
