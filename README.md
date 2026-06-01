# 🏢 Modern Data Warehouse Architecture: From Source to Insights

## 📋 Project Overview

This project demonstrates the design and implementation of an enterprise-grade Data Warehouse built entirely on Microsoft SQL Server using a layered Medallion Architecture approach.

The solution ingests operational data from multiple business systems, including Customer Relationship Management (CRM) and Enterprise Resource Planning (ERP) platforms, and transforms it through three distinct layers:

* 🥉 Bronze Layer – Raw Data Ingestion
* 🥈 Silver Layer – Data Cleansing & Standardization
* 🥇 Gold Layer – Business Intelligence & Semantic Modeling

The primary objective is to establish a scalable, maintainable, and analytics-ready data platform that ensures:

* Reliable data ingestion
* Enterprise data quality standards
* Cross-system data integration
* Historical data preservation
* Business-friendly analytical models
* End-to-end data lineage

The Gold Layer is implemented using SQL Server Views that expose a virtualized Star Schema optimized for Power BI, Tableau, SSRS, and ad-hoc analytics.

---

# 🏗️ Architecture Overview

The warehouse follows a layered architecture to guarantee fault isolation, reproducibility, and complete data traceability.

```text
                    +----------------------+
                    |      CRM Sources     |
                    +----------+-----------+
                               |
                               |
                    +----------v-----------+
                    |      ERP Sources     |
                    +----------+-----------+
                               |
                               v
+-------------------------------------------------------------------+
| 🥉 BRONZE LAYER                                                    |
| Raw Data Ingestion & Staging                                      |
|                                                                   |
| • crm_cust_info                                                   |
| • crm_prd_info                                                    |
| • crm_sales_details                                               |
| • erp_cust_az12                                                   |
| • erp_loc_a101                                                    |
| • erp_px_cat_g1v2                                                 |
+-------------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------------+
| 🥈 SILVER LAYER                                                    |
| Data Cleansing, Validation & Standardization                     |
|                                                                   |
| • Data Quality Enforcement                                        |
| • Business Key Reconciliation                                     |
| • Historical Timeline Repair                                      |
| • Date Standardization                                            |
| • Customer & Product Mastering                                    |
+-------------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------------+
| 🥇 GOLD LAYER                                                      |
| Virtualized Star Schema (SQL Views)                               |
|                                                                   |
| Dimension Views                                                   |
| • gold.dim_customers                                               |
| • gold.dim_products                                                |
|                                                                   |
| Fact View                                                         |
| • gold.fact_sales                                                  |
+-------------------------------------------------------------------+
```

> **Note:** The Gold Layer is implemented entirely through SQL Views rather than physical tables. This virtualized approach provides a lightweight semantic layer while maintaining a single source of truth within the Silver layer.

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

The Bronze Layer serves as the immutable landing zone for source system extracts.

Data is loaded exactly as received from CRM and ERP systems without applying business transformations or validation rules.

## Characteristics

* Raw source preservation
* Flexible schema design
* No business constraints
* Historical auditability
* Fault-tolerant ingestion
* Re-runnable loading processes

## Components

| Script                      | Description                            |
| --------------------------- | -------------------------------------- |
| build_tables.sql            | Creates Bronze staging tables          |
| create_stored_procedure.sql | Creates automated ingestion procedures |
| populating_tables.sql       | Loads CRM and ERP source datasets      |

## Features

* Bulk loading framework
* TRY...CATCH error handling
* Execution tracking
* Load monitoring
* Truncate-and-reload pattern

---

# 🥈 Silver Layer – Data Cleansing & Standardization

## Purpose

The Silver Layer transforms raw operational data into trusted enterprise datasets.

This layer applies data quality checks, business rules, standardization logic, and cross-system integrations.

---

## Key Transformations

### Customer Standardization

* Removes leading and trailing whitespace
* Standardizes customer attributes
* Validates customer identifiers

### Product Timeline Reconstruction

Historical product records contained invalid date sequences.

The pipeline reconstructs product history using SQL window functions to create valid historical intervals.

### ERP Customer Integration

Legacy ERP identifiers containing prefixes such as:

```text
NAS12345
```

are standardized to align with CRM customer records.

### Geographic Standardization

Country values are normalized into standardized business formats.

Examples:

```text
US
USA
United States
DE
Germany
```

become consistent reporting values.

### Transaction Validation

Sales transactions are validated using business rules such as:

```text
Sales Amount = Quantity × Price
```

Additional checks include:

* Future date prevention
* Missing value handling
* Negative value correction
* Date standardization

---

# 🥇 Gold Layer – Business Intelligence & Semantic Modeling

## Purpose

The Gold Layer provides business-ready analytical datasets through SQL Views.

Rather than storing duplicated dimensional tables, the Gold Layer exposes a virtualized Star Schema built directly on top of the cleansed Silver layer.

---

## Why Views Instead of Physical Tables?

The Gold layer intentionally uses Views instead of materialized tables.

### Benefits

* Eliminates data duplication
* Reduces storage requirements
* Simplifies maintenance
* Provides real-time access to Silver-layer data
* Ensures a single source of truth
* Removes additional ETL refresh dependencies

---

## Gold Layer Objects

### gold.dim_customers

Customer dimension view containing:

* Customer demographics
* Geographic attributes
* Customer lifecycle information

### gold.dim_products

Product dimension view containing:

* Product hierarchy
* Product categorization
* Product attributes
* Product history information

### gold.fact_sales

Sales fact view containing:

* Sales transactions
* Revenue metrics
* Product relationships
* Customer relationships
* Date dimensions

---

# ⭐ Virtualized Star Schema

```text
                     gold.dim_customers
                             |
                             |
                      customer_key
                             |
                             |
gold.dim_products ---- gold.fact_sales
      product_key             |
                              |
                       customer_key
```

The Gold layer exposes a reporting-friendly Star Schema while preserving the Silver layer as the single source of truth.

---

# ⚙️ Data Quality Framework

The project incorporates automated data quality validation to ensure data integrity throughout the pipeline.

## Validation Categories

### Business Key Validation

Ensures:

* No missing identifiers
* No duplicate business keys
* Consistent record grain

### Referential Integrity

Verifies:

* No orphan sales records
* Valid customer relationships
* Valid product relationships

### Chronological Validation

Checks:

* Order Date ≤ Shipping Date
* Product Start Date ≤ Product End Date

### Financial Validation

Ensures:

```text
Sales Amount = Quantity × Price
```

for every sales transaction.

---

# 🧪 Testing Framework

The repository includes a dedicated testing suite:

```text
tests/silver_data_quality_tests.sql
```

The framework follows an Exception Testing methodology.

### Expected Result

Every validation query should return:

```text
0 Rows Returned
```

Any returned records indicate data quality issues requiring investigation.

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

* DataWarehouse database
* Bronze schema
* Silver schema
* Gold schema

---

## Step 2 – Deploy Bronze Layer

```bash
sqlcmd -S <server_name> -d DataWarehouse -i scripts/bronze/build_tables.sql

sqlcmd -S <server_name> -d DataWarehouse -i scripts/bronze/create_stored_procedure.sql

sqlcmd -S <server_name> -d DataWarehouse -i scripts/bronze/populating_tables.sql
```

---

## Step 3 – Deploy Silver Layer

```bash
sqlcmd -S <server_name> -d DataWarehouse -i scripts/silver/table_creation.sql

sqlcmd -S <server_name> -d DataWarehouse -i scripts/silver_layer_stored_procedure.sql
```

---

## Step 4 – Deploy Gold Layer

```bash
sqlcmd -S <server_name> -d DataWarehouse -i scripts/gold/gold.dim_customers.sql

sqlcmd -S <server_name> -d DataWarehouse -i scripts/gold/gold.dim_products.sql

sqlcmd -S <server_name> -d DataWarehouse -i scripts/gold/gold.fact_sales.sql
```

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

# 📈 Business Capabilities

The warehouse enables:

* Customer Segmentation Analysis
* Product Performance Analysis
* Revenue Trend Reporting
* Geographic Sales Analysis
* Customer Lifetime Value Analysis
* Product Category Reporting
* Executive KPI Dashboards

---

# 🛠️ Technologies Used

* Microsoft SQL Server
* T-SQL
* SQL Server Management Studio (SSMS)
* SQLCMD
* Data Warehousing
* Medallion Architecture
* Virtualized Star Schema
* Dimensional Modeling
* Data Quality Engineering

---

# 🎯 Skills Demonstrated

* Enterprise Data Warehouse Design
* ETL Development
* Data Modeling
* Data Quality Engineering
* SQL Performance Optimization
* Dimensional Modeling
* Star Schema Design
* Semantic Layer Design
* Virtualized Data Warehousing
* Master Data Integration
* Business Intelligence Enablement

---

# 📄 License

This project is intended for educational, portfolio, and professional demonstration purposes.

Feel free to fork, modify, and extend the solution for additional analytics, reporting, and cloud data platform integrations.
