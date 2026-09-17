/* Export the complete result grid as data/processed/dates.csv. */

USE olist_portfolio;

SELECT
    calendar_date,
    calendar_year,
    month_number,
    month_name,
    month_start
FROM powerbi_dates
ORDER BY calendar_date;
