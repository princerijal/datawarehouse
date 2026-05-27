/*

PURPOSE:
    The purpose of this script is to populate all of the tables created in bronze layer
I am using BULK INSERT function


WARNING:

Check the table names and run this script carefully as the script truncates the table first and then only populates them


*/

-- THE TABLE IS TRUBNCATED so that, even if the script is run, the data wont be added 2 times
TRUNCATE TABLE bronze.crm_cust_info;

BULK INSERT bronze.crm_cust_info
FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\cust_info.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
)


SELECT TOP 10 * FROM bronze.crm_cust_info


TRUNCATE TABLE Bronze.crm_prod_info

BULK INSERT bronze.crm_prod_info
	FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\prd_info.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		)

SELECT TOP 10 * FROM bronze.crm_prod_info




		

TRUNCATE TABLE Bronze.crm_sales_details
BULK INSERT Bronze.crm_sales_details
	FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_crm\sales_details.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	)

	SELECT * FROM Bronze.crm_sales_details






TRUNCATE TABLE Bronze.erp_cat_g1v2
BULK INSERT Bronze.erp_cat_g1V2
FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\px_cat_g1v2.csv'
WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
)


SELECT * FROm Bronze.erp_cat_g1v2



TRUNCATE TABLE Bronze.erp_cust_az12

BULK INSERT Bronze.erp_cust_az12
	FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\cust_az12.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	)

SELECT * FROM Bronze.erp_cust_az12



TRUNCATE TABLE Bronze.erp_loc_a101

BULK INSERT Bronze.erp_loc_a101
	FROM 'C:\Users\SRijal\Desktop\SQL\DataWarehouse\datasets\source_erp\loc_a101.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	)

SELECT * FROM Bronze.erp_loc_a101
