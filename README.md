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
- **Raw data:** not included in this repository. Download the nine original CSV files from the linked Kaggle dataset and place them in `data/raw/` before running the SQL.
- **Tableau inputs:** three SQL-generated CSV files in `data/processed/`
- **Data licence:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — attribution to Olist, non-commercial use, and the same licence for derived data

## SQL workflow

1. **Set up:** [`sql/01_setup/`](sql/01_setup/) creates the database and raw tables. Import the nine source CSVs separately using the instructions below.
2. **Clean the data:** [`sql/02_cleaning/`](sql/02_cleaning/) standardises text, converts dates and numbers, handles missing values, and validates cleaned tables.
3. **Explore the data:** [`sql/03_analysis/`](sql/03_analysis/) examines order statuses, the fulfilment funnel, delivery performance, reviews, monthly trends, and customer states.
4. **Prepare Tableau inputs:** [`sql/04_exports/`](sql/04_exports/) creates the export tables, then selects the results for CSV export.

The export scripts retain their original `powerbi_` table names. These same tables supply the CSV files used in Tableau.

## Tableau CSV exports

| File | Contents |
| --- | --- |
| [`orders.csv`](data/processed/orders.csv) | One row per order, with customer state, fulfilment flags, delivery metrics, latest review score, and order values |
| [`order_items.csv`](data/processed/order_items.csv) | One row per order item, with product category, seller, price, and freight |
| [`dates.csv`](data/processed/dates.csv) | Calendar dates and month attributes for filtering and trends |

## Importing the raw data

I originally imported the nine CSV files through MySQL Workbench using scripted `LOAD DATA LOCAL INFILE` statements. Source fields were stored as text, and imported row counts were checked before cleaning. The import scripts are excluded from this repository because they contain file paths specific to my computer.

To reproduce the project, download the dataset from Kaggle, extract its nine CSV files, and place them in a `data/raw/` folder that you create locally. Run `01_create_database.sql` and `02_create_raw_tables.sql` in `sql/01_setup/`, then import each CSV into its corresponding existing table in the `olist_portfolio` database:

| Source CSV | Existing table | Expected data rows |
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

Use MySQL Workbench's [Table Data Import Wizard](https://dev.mysql.com/doc/workbench/en/wb-admin-export-import-table.html), available by right-clicking a table, or your own CSV import method. Select the existing table, use UTF-8 encoding, skip the CSV header, and map columns by their source names. Preserve source values as text and empty fields as empty strings. Leave `raw_row_id` and `ingested_at` unmapped so MySQL generates them automatically.

The reviews CSV contains quoted multiline comments, so use an import method that handles these correctly. Compare imported row counts with the table above using the count query at the end of `02_create_raw_tables.sql` before running the cleaning scripts.

## How to run the project

1. Open MySQL Workbench with MySQL 8.0 or later.
2. Download the Olist dataset from the linked Kaggle page, extract the nine source CSV files, and place them in a local `data/raw/` folder.
3. Run the database and raw-table creation scripts in `sql/01_setup/`, then import the CSVs yourself using the mapping and instructions above.
4. Run the cleaning scripts in `sql/02_cleaning/`, followed by the analysis scripts in `sql/03_analysis/`, in numbered-file order. Select the `olist_portfolio` schema when running analysis queries.
5. Review the validation results in the cleaning scripts. Run `01_create_powerbi_export_tables.sql`, then export the complete results of `02_export_dates.sql`, `03_export_orders.sql`, and `04_export_order_items.sql` as CSV files with column headers in `data/processed/`.
6. Connect Tableau to the three CSV files. Relate `orders.order_date` to `dates.calendar_date`, and `orders.order_key` to `order_items.order_key`.

The existing CSV exports can also be opened directly in Tableau without running MySQL.

## Author

[jmtadpatrikar](https://github.com/jmtadpatrikar)
