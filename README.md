# 🏗️ Project Architecture

This project follows a layered Enterprise Data Warehouse design inspired by the Medallion Architecture pattern. The repository is organized into logical components that separate ingestion, transformation, validation, and documentation responsibilities.

```text
datawarehouse/
│
├── datasets/
│   └── Source CRM and ERP datasets
│
├── docs/
│   └── Project documentation and design notes
│
├── scripts/
│   │
│   ├── init_database_and_Schemas.sql
│   │
│   ├── bronze/
│   │   ├── build_tables.sql
│   │   ├── create_stored_procedure.sql
│   │   └── populating_tables.sql
│   │
│   └── silver/
│       ├── table_creation.sql
│       ├── silver.crm_cust_info.sql
│       ├── silver_crm_prd_info.sql
│       ├── silver.crm_sales_details.sql
│       ├── silver.erp_cust_az12.sql
│       ├── load_silver.erp_loc_a101.sql
│       └── silver.erp_px_cat_g1v2.sql
│
├── tests/
│   └── Data quality validation scripts
│
└── README.md
```

## Bronze Layer

The Bronze layer acts as the raw data landing zone.

### Responsibilities

- Create raw staging tables
- Load source CRM and ERP datasets
- Preserve source system structure
- Capture ingestion errors
- Enable rerunnable ingestion processes

### Scripts

| Script | Purpose |
|----------|----------|
| build_tables.sql | Creates Bronze staging tables |
| populating_tables.sql | Loads raw source data |
| create_stored_procedure.sql | Implements automated loading framework with execution logging and error handling |

---

## Silver Layer

The Silver layer performs cleansing, standardization, validation, and integration.

### Responsibilities

- Data quality enforcement
- Cross-system integration
- Standardized business entities
- Historical reconstruction
- Fact and dimension preparation

### Scripts

| Script | Purpose |
|----------|----------|
| table_creation.sql | Creates Silver layer structures |
| silver.crm_cust_info.sql | Customer cleansing and standardization |
| silver_crm_prd_info.sql | Product dimension timeline reconstruction |
| silver.crm_sales_details.sql | Sales fact table validation and transformation |
| silver.erp_cust_az12.sql | ERP customer enrichment |
| load_silver.erp_loc_a101.sql | Location cleansing and country standardization |
| silver.erp_px_cat_g1v2.sql | Product category mapping integration |

---

## Testing Layer

The `tests` directory contains validation scripts that verify:

- Data completeness
- Referential integrity
- Business rule compliance
- Financial calculation accuracy
- Timeline consistency

All validation scripts are expected to return **zero exception records** after successful execution.
