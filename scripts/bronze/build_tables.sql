
-- Building bronze layer

/*
-------------------------------------------
 THIS SCRIPT CREATES THE TABLES FOR THE BRONZE LAYER WHICH i AM REFERRING AS BRONZE SCHEMA

 --------------------W A R N I N G --------------
 RUNNING THIS SCRIPT WILL DELETE IF THE TABLES NAMED BELOW EXISTS AND THEM RECREATES THEM FROM THE SCRATCH

*/
USE DataWarehouse;

-- Creating tables
-- CRM is the source name

IF OBJECT_ID('Bronze.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE Bronze.crm_cust_info
CREATE TABLE Bronze.crm_cust_info(
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(30),
	cst_gndr VARCHAR(20),
	cst_create_date DATE
);

IF OBJECT_ID('Bronze.crm_prod_info', 'U') IS NOT NULL
	DROP TABLE Bronze.crm_prod_info;

CREATE TABLE Bronze.crm_prod_info(
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line VARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE
)

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT, 
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT

)


-- Now here ERP is the source
IF OBJECT_ID('Bronze.erp_cust_az12', 'U') IS NOT NULL
	 DROP TABLE Bronze.erp_cust_az12;

CREATE TABLE Bronze.erp_cust_az12(
	cid NVARCHAR(50),
	bdate DATE,
	gen VARCHAR(20)
)

IF OBJECT_ID('Bronze.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE Bronze.erp_loc_a101;
CREATE TABLE Bronze.erp_loc_a101(
	cid NVARCHAR(50),
	cntry VARCHAR(50)
)

IF OBJECT_ID('Bronze.erp_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE Bronze.erp_cat_g1v2;

CREATE TABLE Bronze.erp_cat_g1v2(
	id NVARCHAR(50),
	cat VARCHAR(50),
	SUBCAT VARCHAR(50),
	MAINTENANCE VARCHAR(10)
)



