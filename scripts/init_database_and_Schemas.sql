/*
 =========================================
 Create Database and Schemas

 The Purpose of this script is to create a new database and schemas of names: Bronze, Silver and Gold


---------------------WARNING-------------------------------------------------------------
 Please note that running this script will drop(Delete) and then recreate the database named 'DataWarehouse'




*/


-- First Create a new database and use it
USE MASTER;
GO

-- DROP and Recreate the 'DataWarehouse' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
	BEGIN
		ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE DataWarehouse;
	END
GO

CREATE DATABASE DataWarehouse;
GO

USE Datawarehouse;

--Creating schemas for Bronze, Silver and Gold

CREATE Schema Bronze;
GO
CREATE SCHEMA silver;
GO
CREATE Schema gold;
GO


-- If schemas are not shown, then check where they might be with the following

SELECT catalog_name, schema_name 
FROM information_schema.schemata
WHERE schema_name = 'bronze';


-- Check if anything is there inside the schemas
USE master;
GO

SELECT 
    s.name AS schema_name, 
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('bronze', 'silver', 'gold')
ORDER BY schema_name, table_name;


-- If the schemas are created in master or other databases
-- Run these scripts to delete them

DROP SCHEMA IF EXISTS bronze;
DROP SCHEMA IF EXISTS silver;
DROP SCHEMA IF EXISTS gold;
