# Investment Risk Management: Data Warehousing and Analytics Solution

![License](https://img.shields.io/badge/license-MIT-blue.svg)

The "Investment Risk Management" project is a comprehensive data warehouse and analytics platform designed to monitor financial performance, assess risks, and support data-driven decision-making. It combines a robust star schema design with pre-aggregated materialized views for advanced reporting.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Setup Instructions](#setup-instructions)
- [Project Structure](#project-structure)
- [Analytics Capabilities](#analytics-capabilities)
- [Contributing](#contributing)
- [License](#license)

## Overview
This project integrates **data warehousing** and **analytics** to provide a scalable solution for investment risk management. Key features include:
- Star schema design with dimension and fact tables.
- Automated ETL processes for data transformation and loading.
- Pre-aggregated materialized views for faster reporting.
- Hierarchical representation of sectors and geographical data.

## Features
### Data Warehousing
- **Star Schema**: Centralized fact table (`FACT_FINANCING`) with dimensions like `DIM_DATE`, `DIM_CUSTOMER`, and `DIM_SECTOR`.
- **Partitioning**: Optimized storage and query performance.
- **Indexing**: B-tree, and indexes for efficient querying.

### ETL Processes
- **Data Transformation**: Boolean columns, date parsing, and text standardization.
- **Automation**: Stored procedures for seamless data ingestion.
- **Error Handling**: Comprehensive logging for ETL workflows.

### Analytics
- **Materialized Views**: Pre-aggregated data for business intelligence.
- **Risk Assessment**: Loan classification statuses and risk weights.
- **Time-Based Analysis**: Yearly, quarterly, and monthly breakdowns.
- **Geographical Insights**: Hierarchical analysis by division, zone, district, and thana.

## Technologies Used
- Oracle Database
- SQL and PL/SQL
- Python (for data ingestion)
- Materialized Views
- Partitioning and Indexing

## Setup Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/masumhowlader/Investment-Risk-Management---Data-Warehousing-and-Analytics
2. Set up an Oracle database instance.
3. Set up python environment to work with Oracle database
4. Run the SQL scripts in the scripts/database-script/ddl folder to create tables, procedures, and materialized views.
5. Run the python scripts in the scripts/python-script folder for data ingestion
6. Run the SQL scripts in the scripts/database-script/dml folder for data cleasning, transformation and data loading.
7. Use the sample CSV files in the data/ folder for testing.

## Project Structure
Investment-Risk-Management-Analytics/
│
├── README.md
├── scripts/
│   ├── create_tables.sql
│   ├── load_data.sql
│   ├── materialized_views.sql
│   └── stored_procedures.sql
├── data/
│   ├── branches.csv
│   ├── customers.csv
│   └── products.csv
└── docs/
    ├── ER_Diagram.png
    └── Data_Flow_Diagram.png

## Analytics Capabilities
- **Business Unit Analysis** : Total outstanding balance and classified amounts by business unit.
- **Loan Classification** : Risk-weighted analysis of loan statuses.
- **Customer Insights** : Customer-wise financing and type-based aggregations.
- **Geographical Breakdown** : Hierarchical analysis by division, zone, district, and thana.

