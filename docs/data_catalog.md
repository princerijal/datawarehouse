# 📚 Data Catalog

## Overview

This document provides metadata and business definitions for the Gold Layer semantic model.

The Gold Layer is implemented entirely through SQL Server Views rather than physical tables. These views expose business-ready datasets built from the cleansed and standardized Silver Layer.

### Gold Layer Objects

| Object Name        | Object Type | Purpose                 |
| ------------------ | ----------- | ----------------------- |
| gold.dim_customers | View        | Customer dimension view |
| gold.dim_products  | View        | Product dimension view  |
| gold.fact_sales    | View        | Sales fact view         |

### Design Philosophy

The Gold Layer utilizes virtualized dimensional modeling to provide:

* Real-time access to Silver-layer data
* Reduced storage requirements
* Simplified maintenance
* Elimination of redundant data copies
* Consistent business definitions across reporting tools

---

# 👤 gold.dim_customers

## Object Type

**SQL View**

## Description

Business-facing customer dimension view containing standardized customer demographic and geographic attributes.

## Grain

One record per customer.

## Source

Derived from:

```text
silver.crm_cust_info
silver.erp_cust_az12
silver.erp_loc_a101
```

## Columns

| Column Name     | Data Type    | Description                        |
| --------------- | ------------ | ---------------------------------- |
| customer_key    | BIGINT       | Warehouse-generated surrogate key. |
| customer_id     | INT          | Source customer identifier.        |
| customer_number | NVARCHAR(50) | Customer business identifier.      |
| first_name      | NVARCHAR(50) | Customer first name.               |
| last_name       | NVARCHAR(50) | Customer last name.                |
| country         | NVARCHAR(50) | Standardized customer country.     |
| marital_status  | VARCHAR(20)  | Customer marital status.           |
| gender          | VARCHAR(50)  | Standardized gender value.         |
| birth_date      | DATE         | Customer birth date.               |
| create_date     | DATE         | Customer creation date.            |

---

# 📦 gold.dim_products

## Object Type

**SQL View**

## Description

Business-facing product dimension view containing product hierarchy and categorization attributes.

## Grain

One record per product.

## Source

Derived from:

```text
silver.crm_prd_info
silver.erp_px_cat_g1v2
```

## Columns

| Column Name    | Data Type    | Description                        |
| -------------- | ------------ | ---------------------------------- |
| product_key    | BIGINT       | Warehouse-generated surrogate key. |
| product_id     | INT          | Source product identifier.         |
| product_number | NVARCHAR(50) | Product business code.             |
| product_name   | NVARCHAR(50) | Product name.                      |
| category_id    | NVARCHAR(50) | Product category identifier.       |
| category       | VARCHAR(50)  | Product category.                  |
| sub_category   | VARCHAR(50)  | Product subcategory.               |
| maintenance    | VARCHAR(20)  | Maintenance classification.        |
| cost           | INT          | Product cost.                      |
| product_line   | NVARCHAR(50) | Product line grouping.             |
| start_date     | DATE         | Product effective start date.      |

---

# 💰 gold.fact_sales

## Object Type

**SQL View**

## Description

Central business fact view containing sales transactions and quantitative measures.

## Grain

One record per sales order line.

## Source

Derived from:

```text
silver.crm_sales_details
gold.dim_customers
gold.dim_products
```

## Columns

| Column Name   | Data Type    | Description                        |
| ------------- | ------------ | ---------------------------------- |
| order_number  | NVARCHAR(50) | Sales order identifier.            |
| product_key   | BIGINT       | Foreign key to gold.dim_products.  |
| customer_key  | BIGINT       | Foreign key to gold.dim_customers. |
| order_date    | DATE         | Order date.                        |
| shipping_date | DATE         | Shipping date.                     |
| due_date      | DATE         | Expected delivery date.            |
| sales_amount  | INT          | Total transaction value.           |
| quantity      | INT          | Units sold.                        |
| price         | INT          | Unit selling price.                |

---

# ⭐ Gold Layer Star Schema

The Gold Layer follows a virtualized Star Schema design.

```text
                    gold.dim_customers (VIEW)
                               |
                               |
                        customer_key
                               |
                               |
gold.dim_products (VIEW) ---- gold.fact_sales (VIEW)
       product_key                  |
                                    |
                             customer_key
```

Unlike traditional warehouses that physically materialize dimensional tables, this implementation exposes the dimensional model through SQL Views built on top of Silver-layer entities.

This approach provides a lightweight semantic layer optimized for Power BI, Tableau, SSRS, and ad-hoc SQL analytics.
