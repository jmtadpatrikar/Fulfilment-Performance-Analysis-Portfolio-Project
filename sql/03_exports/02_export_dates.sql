/* Export the complete result grid as dates.csv */

USE olist_portfolio;

SELECT
    calendar_date,
    calendar_year,
    month_number,
    month_name,
    month_start
FROM tableau_dates
ORDER BY calendar_date;
