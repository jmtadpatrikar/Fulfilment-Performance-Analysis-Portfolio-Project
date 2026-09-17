# Olist Fulfilment Performance Analysis

A SQL portfolio project that analyses order fulfilment, delivery performance, and customer reviews using MySQL, with results presented in Tableau Public.

## Project overview

This project explores how orders move from purchase to approval, carrier hand-off, and delivery across Olist's Brazilian marketplace data. It uses SQL to compare delivery performance over time and across customer states, and examine how late deliveries are associated with customer review scores.

The Tableau dashboard uses exported CSV files rather than a live MySQL connection. These exports support order and customer totals, delivered product revenue, delivery performance, reviews, and product-category comparisons.

## Skills demonstrated

- SQL and exploratory data analysis
- Data cleaning and type conversion
- Filtering, aggregation, and joins
- Common table expressions (CTEs)
- Window functions using `ROW_NUMBER` to select the latest review per order and create numeric project keys
- Data validation and reconciliation
- Tableau data preparation and visualisation

## Business question

Where does the order fulfilment process lose performance, and how are delivery delays associated with customer satisfaction?

## Explore the interactive Tableau dashboard

> Explore the fulfilment funnel, on-time delivery, customer reviews, monthly performance, and product-category results.

[**Open the interactive Tableau dashboard →**](https://public.tableau.com/app/profile/joe.tadpatrikar/viz/OlistFulfilmentPerformanceDashboard/Dashboard2)

## Key insights

- The core analysis covers 1 January 2017 to 31 August 2018 and includes **99,092 orders**.
- **93.21%** of the 96,203 eligible deliveries arrived on or before the estimated delivery date. **6,531 orders** arrived late.
- Reviewed late deliveries had an average score of **2.27 out of 5**, compared with **4.29** for reviewed on-time deliveries.
- **62.42%** of reviewed late deliveries received a score of 1 or 2, compared with **9.25%** of reviewed on-time deliveries.
- Rio de Janeiro combined high delivery volume with weaker performance: **1,495 of 12,310 deliveries (12.14%)** were late.
- The largest reduction in the recorded fulfilment funnel occurred between approval and carrier hand-off.

These results show an association between delivery delays and review scores. They do not establish that delays caused lower satisfaction.

## Recommendations

- **Investigate the approval-to-carrier hand-off stage.** This is the largest recorded reduction in the fulfilment funnel. Review approved orders without a carrier hand-off, checking final statuses and missing timestamps before identifying operational causes.
- **Prioritise regional delivery reviews.** Rio de Janeiro recorded 1,495 late deliveries and a 12.14% late-delivery rate. São Paulo also warrants attention: despite a 95.50% on-time rate, its higher volume resulted in 1,817 late deliveries. Consider both late-order volume and lateness rate when allocating effort.
- **Test proactive communication for delayed orders.** Reviewed late deliveries scored 2.27 out of 5 on average, compared with 4.29 for on-time deliveries. Pilot earlier delay notifications and customer-support follow-up, then measure whether review outcomes improve.
- **Validate priorities with recent data and monitor results.** Track monthly on-time delivery rates, late-order volumes, and low-score review rates by customer state. Use these measures to evaluate interventions, since this historical dataset does not establish current performance.

## Tools used

- MySQL
- MySQL Workbench
- Tableau Public
- CSV exports

## Dataset

This project uses the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

- **Source coverage:** order purchases from 4 September 2016 to 17 October 2018
- **Analysis period:** 1 January 2017 to 31 August 2018
- **Source files:** nine CSVs covering orders, customers, items, payments, reviews, products, sellers, category translations, and geolocation
- **Raw data:** not included in this repository. Download the nine original CSV files from the linked Kaggle dataset and save them locally before running the SQL.
- **Tableau inputs:** three SQL-generated CSV files in the top-level `processed_data/` folder
- **Data licence:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — attribution to Olist, non-commercial use, and the same licence for derived data

## Repository structure

```text
README.md
processed_data/
├── dates.csv
├── order_items.csv
└── orders.csv
sql/
├── 01_cleaning/
│   ├── 01_create_clean_orders.sql
│   ├── 02_create_clean_dimensions.sql
│   ├── 03_create_clean_order_items.sql
│   ├── 04_create_clean_order_payments.sql
│   └── 05_create_clean_order_reviews.sql
├── 02_analysis/
│   ├── 01_EDA.sql
│   ├── 02_fulfilment_funnel.sql
│   ├── 03_delivery_performance.sql
│   ├── 04_delivery_review_analysis.sql
│   ├── 05_monthly_delivery_performance.sql
│   └── 06_customer_state_delivery_performance.sql
└── 03_exports/
    ├── 01_create_tableau_export_tables.sql
    ├── 02_export_dates.sql
    ├── 03_export_orders.sql
    └── 04_export_order_items.sql
```

`processed_data/` and `sql/` are both at the repository's top level. The downloaded raw CSV files are kept locally and are not part of the repository.

## SQL workflow

Create the `olist_portfolio` database and import the nine source CSVs yourself using the instructions below. Database setup and import scripts are not included. Then run the supplied SQL folders in this order:

1. **Clean the data:** [`sql/01_cleaning/`](sql/01_cleaning/) standardises text, converts dates and numbers, handles missing values, and validates cleaned tables.
2. **Explore the data:** [`sql/02_analysis/`](sql/02_analysis/) examines order statuses, the fulfilment funnel, delivery performance, reviews, monthly trends, and customer states.
3. **Prepare Tableau inputs:** [`sql/03_exports/`](sql/03_exports/) creates the export tables, then selects the results for CSV export.

The export scripts create `tableau_dates`, `tableau_orders`, and `tableau_order_items`, which supply the three CSV files used in Tableau.

## Tableau CSV exports

| File | Contents |
| --- | --- |
| [`orders.csv`](processed_data/orders.csv) | One row per order, with customer state, fulfilment flags, delivery metrics, latest review score, and order values |
| [`order_items.csv`](processed_data/order_items.csv) | One row per order item, with product category, seller, price, and freight |
| [`dates.csv`](processed_data/dates.csv) | Calendar dates and month attributes for filtering and trends |

## Importing the raw data

I originally imported the nine CSV files through MySQL Workbench using scripted `LOAD DATA LOCAL INFILE` statements. Source fields were stored as text, and imported row counts were checked before cleaning. The import scripts are excluded from this repository because they contain file paths specific to my computer.

To reproduce the project, download the dataset from Kaggle and extract its nine CSV files into a local folder of your choice. Create and select the database in MySQL Workbench:

```sql
CREATE DATABASE IF NOT EXISTS olist_portfolio
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs;
USE olist_portfolio;
```

Use MySQL Workbench's [Table Data Import Wizard](https://dev.mysql.com/doc/workbench/en/wb-admin-export-import-table.html), available by right-clicking the schema's **Tables** section, or your own CSV import method. Create a new table for each CSV using the names below:

| Source CSV | MySQL table | Expected data rows |
| --- | --- | ---: |
| `olist_customers_dataset.csv` | `raw_customers` | 99,441 |
| `olist_geolocation_dataset.csv` | `raw_geolocation` | 1,000,163 |
| `olist_order_items_dataset.csv` | `raw_order_items` | 112,650 |
| `olist_order_payments_dataset.csv` | `raw_order_payments` | 103,886 |
| `olist_order_reviews_dataset.csv` | `raw_order_reviews` | 99,224 |
| `olist_orders_dataset.csv` | `raw_orders` | 99,441 |
| `olist_products_dataset.csv` | `raw_products` | 32,951 |
| `olist_sellers_dataset.csv` | `raw_sellers` | 3,095 |
| `product_category_name_translation.csv` | `raw_category_translation` | 71 |

Use UTF-8 encoding and the CSV header as the column names, without importing the header as a data row. Set all source columns to `TEXT` to preserve IDs, dates, numbers, and review comments before the cleaning scripts convert them. Preserve empty fields as empty strings and keep the original column names unchanged.

After importing, add a generated `raw_row_id` primary key to each of the nine raw tables. The cleaning scripts require this column to identify source rows. For example:

```sql
ALTER TABLE raw_orders
    ADD COLUMN raw_row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
```

Repeat this for the other eight table names above. Keep source IDs as text columns rather than using them as primary keys.

The reviews CSV contains quoted multiline comments, so use an import method that handles these correctly. Before cleaning, compare each imported row count with the table above using `SELECT COUNT(*) FROM table_name;`, replacing `table_name` with the relevant raw table.

## How to run the project

1. Open MySQL Workbench with MySQL 8.0 or later.
2. Download the Olist dataset from the linked Kaggle page and extract the nine source CSV files locally.
3. Create the `olist_portfolio` database, import the CSVs into the named raw tables, and add their `raw_row_id` columns using the instructions above.
4. Run the cleaning scripts in `sql/01_cleaning/`, followed by the analysis scripts in `sql/02_analysis/`, in numbered-file order. Select the `olist_portfolio` schema when running analysis queries.
5. Review the validation results in the cleaning scripts. In `sql/03_exports/`, run [`01_create_tableau_export_tables.sql`](sql/03_exports/01_create_tableau_export_tables.sql), then export the complete results of [`02_export_dates.sql`](sql/03_exports/02_export_dates.sql), [`03_export_orders.sql`](sql/03_exports/03_export_orders.sql), and [`04_export_order_items.sql`](sql/03_exports/04_export_order_items.sql) as `dates.csv`, `orders.csv`, and `order_items.csv` respectively, with column headers in `processed_data/`.
6. Connect Tableau to `processed_data/orders.csv`, `processed_data/order_items.csv`, and `processed_data/dates.csv`. Relate `orders.order_date` to `dates.calendar_date`, and `orders.order_key` to `order_items.order_key`.

The existing CSV exports can also be opened directly in Tableau without running MySQL.

## Author

[jmtadpatrikar](https://github.com/jmtadpatrikar)
