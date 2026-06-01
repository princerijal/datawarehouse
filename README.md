# 🏢 Modern Data Warehouse Architecture: From Source to Insights

## 📋 Project Overview

This project demonstrates the design and implementation of a modern, enterprise-grade Data Warehouse built entirely on Microsoft SQL Server using a layered Medallion Architecture approach.

The solution ingests operational data from multiple business systems, including Customer Relationship Management (CRM) and Enterprise Resource Planning (ERP) platforms, and transforms it through a structured pipeline consisting of Bronze, Silver, and Gold layers.

The primary objective is to establish a scalable, maintainable, and analytics-ready data platform that ensures:

* Reliable data ingestion
* Data quality enforcement
* Standardized business entities
* Historical data preservation
* High-performance analytical reporting

The final output is a dimensional Star Schema optimized for Business Intelligence tools such as Power BI, Tableau, and SQL Server Reporting Services (SSRS).

---

# 🏗️ Data Warehouse Architecture

The warehouse follows a layered architecture to guarantee data lineage, fault isolation, and reproducible processing.

```text
                    +--------------------+
                    | CRM Source Systems |
                    +---------+----------+
                              |
                              |
                    +---------v----------+
                    | ERP Source Systems |
                    +---------+----------+
                              |
                              v
+----------------------------------------------------------------+
| 🥉 BRONZE LAYER                                                 |
| Raw Data Ingestion & Staging                                   |
|                                                                |
| • crm_cust_info                                                |
| • crm_prd_info                                                 |
| • crm_sales_details                                            |
| • erp_cust_az12                                                |
| • erp_loc_a101                                                 |
| • erp_px_cat_g1v2                                              |
+----------------------------------------------------------------+
                              |
                              v
+----------------------------------------------------------------+
| 🥈 SILVER LAYER                                                 |
| Data Cleansing, Validation & Standardization                   |
|                                                                |
| • Data Quality Enforcement                                     |
| • Business Key Reconciliation                                  |
| • Date Standardization                                         |
| • Customer & Product Mastering                                 |
| • Transaction Validation                                       |
+----------------------------------------------------------------+
                              |
                              v
+----------------------------------------------------------------+
| 🥇 GOLD LAYER                                                   |
| Business Intelligence & Star Schema                            |
|                                                                |
| Dimensions:                                                    |
| • dim_customers                                                |
| • dim_products                                                 |
|                                                                |
| Fact Table:                                                    |
| • fact_sales                                                   |
+----------------------------------------------------------------+
```

---

# 📁 Repository Structure

```text
datawarehouse/
│
├── datasets/
│   └── Source CRM and ERP datasets
│
├── docs/
│   └── Architecture diagrams and documentation
│
├── scripts/
│   │
│   ├── bronze/
│   │   ├── build_tables.sql
│   │   ├── create_stored_procedure.sql
│   │   └── populating_tables.sql
│   │
│   ├── silver/
│   │   ├── table_creation.sql
│   │   ├── load_silver_erp_loc_a101.sql
│   │   ├── silver.crm_cust_info.sql
│   │   ├── silver.crm_sales_details.sql
│   │   ├── silver.erp_cust_az12.sql
│   │   ├── silver.erp_px_cat_g1v2.sql
│   │   └── silver_crm_prd_info.sql
│   │
│   ├── gold/
│   │   ├── gold.dim_customers.sql
│   │   ├── gold.dim_products.sql
│   │   └── gold.fact_sales.sql
│   │
│   ├── init_database_and_Schemas.sql
│   └── silver_layer_stored_procedure.sql
│
├── tests/
│   └── silver_data_quality_tests.sql
│
└── README.md
```

---

# 🥉 Bronze Layer – Raw Data Ingestion

## Purpose

The Bronze Layer acts as the immutable landing zone for all source data extracts.

This layer preserves source data exactly as received without applying business transformations.

## Key Characteristics

* Raw data preservation
* Schema flexibility
* No business constraints
* Historical auditability
* Fault-tolerant ingestion

## Components

| Script                      | Purpose                                |
| --------------------------- | -------------------------------------- |
| build_tables.sql            | Creates Bronze staging tables          |
| create_stored_procedure.sql | Creates automated ingestion procedures |
| populating_tables.sql       | Loads CRM and ERP source data          |

## Features

* Bulk-load processing
* TRY...CATCH error handling
* Execution logging
* Rerunnable ingestion framework

---

# 🥈 Silver Layer – Data Cleansing & Standardization

## Purpose

The Silver Layer transforms raw source data into trusted enterprise datasets.

This layer enforces business rules, data quality standards, and cross-system integration logic.

## Key Transformations

### Customer Standardization

* Remove leading/trailing spaces using TRIM()
* Standardize customer attributes
* Validate customer identifiers

### Product Timeline Reconstruction

Product history records are reconstructed using:

```sql
LEAD()
```

to ensure valid product lifecycle periods.

### ERP Customer Integration

Legacy identifiers containing prefixes such as:

```text
NAS12345
```

are standardized using string manipulation techniques to restore CRM-to-ERP linkage.

### Geographic Standardization

Country codes such as:

```text
US
USA
United States
DE
Germany
```

are consolidated into standardized business values.

### Transaction Validation

Financial integrity is enforced through:

```text
Sales Amount = Quantity × Price
```

Additional validations include:

* Future date removal
* Negative value correction
* Null handling
* Date standardization

---

# 🥇 Gold Layer – Business Intelligence Modeling

## Purpose

The Gold Layer delivers business-ready datasets optimized for reporting and analytics.

Rather than storing duplicated tables, the Gold Layer is implemented using virtualized SQL views.

This approach provides:

* Real-time data availability
* Reduced storage requirements
* Simplified maintenance
* Faster deployment cycles

## Star Schema Design

### Dimension Views

#### dim_customers

Provides:

* Customer demographics
* Customer geography
* Customer attributes

#### dim_products

Provides:

* Product hierarchy
* Product category
* Product metadata

### Fact View

#### fact_sales

Captures:

* Sales transactions
* Revenue metrics
* Product relationships
* Customer relationships

---

# ⚙️ Pipeline Design Features

## Idempotent Processing

All scripts support safe reruns through controlled truncation and reload mechanisms.

Benefits:

* No duplicate data
* Consistent execution
* Simplified deployment

---

## Surrogate Key Generation

Business identifiers are replaced with warehouse-generated surrogate keys using:

```sql
ROW_NUMBER()
```

Benefits:

* Faster joins
* Stable relationships
* Improved analytical performance

---

## Data Lineage

The architecture maintains complete traceability from:

```text
Source Systems
      ↓
Bronze Layer
      ↓
Silver Layer
      ↓
Gold Layer
```

allowing every metric to be traced back to its original source.

---

# 🚀 Deployment Guide

## Prerequisites

* Microsoft SQL Server 2016+
* SQL Server Management Studio (SSMS)
* SQLCMD Utility

---

## Step 1 – Initialize Database

```bash
sqlcmd -S <server_name> -d master -i scripts/init_database_and_Schemas.sql
```

Creates:

* Data Warehouse database
* Bronze schema
* Silver schema
* Gold schema

---

## Step 2 – Deploy Bronze Layer

```bash
sqlcmd -S <server_name> -d datawarehouse -i scripts/bronze/build_tables.sql

sqlcmd -S <server_name> -d datawarehouse -i scripts/bronze/create_stored_procedure.sql

sqlcmd -S <server_name> -d datawarehouse -i scripts/bronze/populating_tables.sql
```

---

## Step 3 – Deploy Silver Layer

```bash
sqlcmd -S <server_name> -d datawarehouse -i scripts/silver/table_creation.sql

sqlcmd -S <server_name> -d datawarehouse -i scripts/silver_layer_stored_procedure.sql
```

---

## Step 4 – Deploy Gold Layer

```bash
sqlcmd -S <server_name> -d datawarehouse -i scripts/gold/gold.dim_customers.sql

sqlcmd -S <server_name> -d datawarehouse -i scripts/gold/gold.dim_products.sql

sqlcmd -S <server_name> -d datawarehouse -i scripts/gold/gold.fact_sales.sql
```

---

# 🧪 Data Quality Assurance

The repository contains a dedicated testing framework:

```text
tests/silver_data_quality_tests.sql
```

The testing suite follows an Exception Testing methodology.

### Success Criteria

Every validation query must return:

```text
0 Rows Returned
```

Any returned rows indicate a data quality issue requiring investigation.

## Validation Categories

### Business Key Validation

Checks:

* Missing identifiers
* Duplicate records
* Invalid business keys

### Referential Integrity

Ensures:

* No orphan transactions
* Valid customer relationships
* Valid product relationships

### Timeline Validation

Verifies:

* Order Date ≤ Ship Date
* Product Start Date ≤ End Date

### Financial Validation

Ensures:

```text
Sales = Quantity × Price
```

across all transactions.

---

# 📊 Example Business Query

Revenue Analysis by Country and Gender

```sql
SELECT
    c.country,
    c.gender,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.sales_amount) AS gross_revenue
FROM gold.fact_sales f
INNER JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
INNER JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    c.country,
    c.gender
ORDER BY
    gross_revenue DESC;
```

---

# 🛠️ Technologies Used

* Microsoft SQL Server
* T-SQL
* SQL Server Management Studio (SSMS)
* SQLCMD
* Data Warehousing
* Medallion Architecture
* Star Schema Modeling
* Data Quality Engineering
* Dimensional Modeling

---

# 🎯 Skills Demonstrated

* Enterprise Data Warehouse Design
* ETL Development
* Data Quality Engineering
* SQL Performance Optimization
* Star Schema Design
* Dimensional Modeling
* Master Data Management
* Data Governance
* Business Intelligence Preparation
* SQL Server Administration

---

# 📄 License

This project is intended for educational, portfolio, and professional demonstration purposes.

Feel free to fork, modify, and extend the solution for additional reporting, analytics, and cloud data platform integrations.
