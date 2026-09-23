use retail;
CREATE VIEW fact_sales AS
SELECT
    s.Sale_ID,
    s.Date,
    s.Store_ID,
    s.Product_ID,
    s.Units,
    p.Product_Category,
    p.Product_Cost,
    p.Product_Price,
    s.Units * p.Product_Price AS Revenue,
    s.Units * p.Product_Cost AS COGS,
    s.Units * (p.Product_Price - p.Product_Cost) AS Gross_Profit,
    (p.Product_Price - p.Product_Cost) / p.Product_Price AS Gross_Margin
FROM sales s
LEFT JOIN products p
    ON s.Product_ID = p.Product_ID;

SELECT COUNT(*) AS fact_rows
FROM fact_sales;

SELECT *
FROM fact_sales
LIMIT 10;

-- Calculate overall business performance KPIs.
-- This provides the high-level financial and sales summary for the project.
SELECT
    COUNT(DISTINCT Sale_ID) AS Total_Transactions,
    SUM(Units) AS Total_Units_Sold,
    SUM(Revenue) AS Total_Revenue,
    SUM(COGS) AS Total_COGS,
    SUM(Gross_Profit) AS Total_Gross_Profit,
    SUM(Gross_Profit) / SUM(Revenue) AS Gross_Margin,
    SUM(Revenue) / COUNT(DISTINCT Sale_ID) AS Average_Revenue_Per_Transaction
FROM fact_sales;

-- Analyze daily sales and profitability performance.
-- Daily granularity supports detailed trend and day-of-week analysis.
SELECT
    Date,
    YEAR(Date) AS Year,
    QUARTER(Date) AS Quarter,
    MONTH(Date) AS Month_Number,
    MONTHNAME(Date) AS Month_Name,
    DAY(Date) AS Day_of_Month,
    DAYOFWEEK(Date) AS Day_of_Week,
    DAYNAME(Date) AS Day_of_Week_Name,
    SUM(Units) AS Units_Sold,
    SUM(Revenue) AS Revenue,
    SUM(COGS) AS COGS,
    SUM(Gross_Profit) AS Gross_Profit,
    SUM(Gross_Profit) / SUM(Revenue) AS Gross_Margin
FROM fact_sales
GROUP BY
    Date,
    YEAR(Date),
    QUARTER(Date),
    MONTH(Date),
    MONTHNAME(Date),
    DAY(Date),
    DAYOFWEEK(Date),
    DAYNAME(Date)
ORDER BY Date;

-- Create daily store performance data.
-- Each row represents one store on one sales date.
SELECT
    f.Date,
    YEAR(f.Date) AS Year,
    QUARTER(f.Date) AS Quarter,
    MONTH(f.Date) AS Month_Number,
    MONTHNAME(f.Date) AS Month_Name,
    f.Store_ID,
    s.Store_Name,
    s.Store_City,
    s.Store_Location,
    SUM(f.Units) AS Units_Sold,
    SUM(f.Revenue) AS Revenue,
    SUM(f.COGS) AS COGS,
    SUM(f.Gross_Profit) AS Gross_Profit,
    SUM(f.Gross_Profit) / SUM(f.Revenue) AS Gross_Margin
FROM fact_sales f
JOIN stores s
    ON f.Store_ID = s.Store_ID
GROUP BY
    f.Date,
    YEAR(f.Date),
    QUARTER(f.Date),
    MONTH(f.Date),
    MONTHNAME(f.Date),
    f.Store_ID,
    s.Store_Name,
    s.Store_City,
    s.Store_Location
ORDER BY
    f.Date,
    f.Store_ID;

-- Create daily product-category performance data.
-- Daily grain supports category trend analysis at any higher time level.
SELECT
    f.Date,
    YEAR(f.Date) AS Year,
    QUARTER(f.Date) AS Quarter,
    MONTH(f.Date) AS Month_Number,
    MONTHNAME(f.Date) AS Month_Name,
    f.Product_Category,
    SUM(f.Units) AS Units_Sold,
    SUM(f.Revenue) AS Revenue,
    SUM(f.COGS) AS COGS,
    SUM(f.Gross_Profit) AS Gross_Profit,
    SUM(f.Gross_Profit) / SUM(f.Revenue) AS Gross_Margin
FROM fact_sales f
GROUP BY
    f.Date,
    YEAR(f.Date),
    QUARTER(f.Date),
    MONTH(f.Date),
    MONTHNAME(f.Date),
    f.Product_Category
ORDER BY
    f.Date,
    f.Product_Category;


-- Create daily product performance data.
-- Daily grain supports product sales and profitability trend analysis.
SELECT
    f.Date,
    YEAR(f.Date) AS Year,
    QUARTER(f.Date) AS Quarter,
    MONTH(f.Date) AS Month_Number,
    MONTHNAME(f.Date) AS Month_Name,
    f.Product_ID,
    p.Product_Name,
    f.Product_Category,
    p.Product_Cost,
    p.Product_Price,
    SUM(f.Units) AS Units_Sold,
    SUM(f.Revenue) AS Revenue,
    SUM(f.COGS) AS COGS,
    SUM(f.Gross_Profit) AS Gross_Profit,
    SUM(f.Gross_Profit) / SUM(f.Revenue) AS Gross_Margin
FROM fact_sales f
JOIN products p
    ON f.Product_ID = p.Product_ID
GROUP BY
    f.Date,
    YEAR(f.Date),
    QUARTER(f.Date),
    MONTH(f.Date),
    MONTHNAME(f.Date),
    f.Product_ID,
    p.Product_Name,
    f.Product_Category,
    p.Product_Cost,
    p.Product_Price
ORDER BY
    f.Date,
    f.Product_ID;


-- Combine current inventory with historical sales performance at Store + Product level.
-- Sales are aggregated first to avoid duplicating inventory records.
WITH sales_summary AS (
    SELECT
        Store_ID,
        Product_ID,
        SUM(Units) AS Units_Sold,
        SUM(Revenue) AS Revenue,
        SUM(COGS) AS COGS,
        SUM(Gross_Profit) AS Gross_Profit
    FROM fact_sales
    GROUP BY
        Store_ID,
        Product_ID
)
SELECT
    i.Store_ID,
    s.Store_Name,
    s.Store_City,
    s.Store_Location,
    i.Product_ID,
    p.Product_Name,
    p.Product_Category,
    i.Stock_On_Hand,
    COALESCE(ss.Units_Sold, 0) AS Units_Sold,
    COALESCE(ss.Revenue, 0) AS Revenue,
    COALESCE(ss.COGS, 0) AS COGS,
    COALESCE(ss.Gross_Profit, 0) AS Gross_Profit,
    CASE
        WHEN COALESCE(ss.Units_Sold, 0) > 0
        THEN i.Stock_On_Hand / ss.Units_Sold
        ELSE NULL
    END AS Stock_to_Sales_Ratio
FROM inventory i
JOIN stores s
    ON i.Store_ID = s.Store_ID
JOIN products p
    ON i.Product_ID = p.Product_ID
LEFT JOIN sales_summary ss
    ON i.Store_ID = ss.Store_ID
    AND i.Product_ID = ss.Product_ID
ORDER BY
    i.Store_ID,
    i.Product_ID;


-- Summarize inventory risk indicators by store.
-- Replenishment risk: low stock with strong historical sales.
-- Overstock risk: high stock with weak historical sales.
WITH sales_summary AS (
    SELECT
        Store_ID,
        Product_ID,
        SUM(Units) AS Units_Sold
    FROM fact_sales
    GROUP BY
        Store_ID,
        Product_ID
),
inventory_analysis AS (
    SELECT
        i.Store_ID,
        i.Product_ID,
        i.Stock_On_Hand,
        COALESCE(ss.Units_Sold, 0) AS Units_Sold
    FROM inventory i
    LEFT JOIN sales_summary ss
        ON i.Store_ID = ss.Store_ID
        AND i.Product_ID = ss.Product_ID
)
SELECT
    ia.Store_ID,
    s.Store_Name,
    s.Store_City,
    s.Store_Location,
    COUNT(*) AS Total_SKUs,
    SUM(
        CASE
            WHEN ia.Stock_On_Hand <= 5
                 AND ia.Units_Sold >= 50
            THEN 1 ELSE 0
        END
    ) AS Replenishment_Risk_SKUs,
    SUM(
        CASE
            WHEN ia.Stock_On_Hand >= 20
                 AND ia.Units_Sold <= 20
            THEN 1 ELSE 0
        END
    ) AS Overstock_Risk_SKUs
FROM inventory_analysis ia
JOIN stores s
    ON ia.Store_ID = s.Store_ID
GROUP BY
    ia.Store_ID,
    s.Store_Name,
    s.Store_City,
    s.Store_Location
ORDER BY
    Replenishment_Risk_SKUs DESC,
    Overstock_Risk_SKUs DESC;

-- Summarize inventory risk by product category.
-- This identifies categories with potential replenishment or overstock issues.
WITH sales_summary AS (
    SELECT
        Store_ID,
        Product_ID,
        SUM(Units) AS Units_Sold
    FROM fact_sales
    GROUP BY
        Store_ID,
        Product_ID
),
inventory_analysis AS (
    SELECT
        i.Store_ID,
        i.Product_ID,
        p.Product_Category,
        i.Stock_On_Hand,
        COALESCE(ss.Units_Sold, 0) AS Units_Sold
    FROM inventory i
    JOIN products p
        ON i.Product_ID = p.Product_ID
    LEFT JOIN sales_summary ss
        ON i.Store_ID = ss.Store_ID
        AND i.Product_ID = ss.Product_ID
)
SELECT
    Product_Category,
    COUNT(*) AS Total_SKUs,
    SUM(
        CASE
            WHEN Stock_On_Hand <= 5
                 AND Units_Sold >= 50
            THEN 1 ELSE 0
        END
    ) AS Replenishment_Risk_SKUs,
    SUM(
        CASE
            WHEN Stock_On_Hand >= 20
                 AND Units_Sold <= 20
            THEN 1 ELSE 0
        END
    ) AS Overstock_Risk_SKUs
FROM inventory_analysis
GROUP BY
    Product_Category
ORDER BY
    Replenishment_Risk_SKUs DESC,
    Overstock_Risk_SKUs DESC;

