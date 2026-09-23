use retail;
SELECT Sale_ID, COUNT(*) AS cnt
FROM sales
GROUP BY Sale_ID
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS invalid_units
FROM sales
WHERE Units <= 0 OR Units IS NULL;

SELECT COUNT(*) AS invalid_store_id
FROM sales s
LEFT JOIN stores st ON s.Store_ID = st.Store_ID
WHERE st.Store_ID IS NULL;

SELECT COUNT(*) AS invalid_product_id
FROM sales s
LEFT JOIN products p ON s.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

SELECT
    SUM(Sale_ID IS NULL) AS null_sale_id,
    SUM(Date IS NULL) AS null_date,
    SUM(Store_ID IS NULL) AS null_store_id,
    SUM(Product_ID IS NULL) AS null_product_id,
    SUM(Units IS NULL) AS null_units
FROM sales;

-- 1. Check duplicate Product_ID
SELECT Product_ID, COUNT(*) AS cnt
FROM products
GROUP BY Product_ID
HAVING COUNT(*) > 1;

-- 2. Check missing values
SELECT
    SUM(Product_ID IS NULL) AS null_product_id,
    SUM(Product_Name IS NULL) AS null_product_name,
    SUM(Product_Category IS NULL) AS null_category,
    SUM(Product_Cost IS NULL) AS null_cost,
    SUM(Product_Price IS NULL) AS null_price
FROM products;

-- 3. Check invalid cost and price
SELECT *
FROM products
WHERE Product_Cost <= 0
   OR Product_Price <= 0;

-- 4. Check whether cost is greater than or equal to selling price
SELECT *
FROM products
WHERE Product_Cost >= Product_Price;

SELECT Store_ID, COUNT(*) AS cnt
FROM stores
GROUP BY Store_ID
HAVING COUNT(*) > 1;
SELECT
    SUM(Store_ID IS NULL) AS null_store_id,
    SUM(Store_Name IS NULL) AS null_store_name,
    SUM(Store_City IS NULL) AS null_city,
    SUM(Store_Location IS NULL) AS null_location,
    SUM(Store_Open_Date IS NULL) AS null_open_date
FROM stores;

SELECT
    COUNT(*) AS store_count,
    MIN(Store_ID) AS min_id,
    MAX(Store_ID) AS max_id
FROM stores;

SELECT
    SUM(Store_ID IS NULL) AS null_store_id,
    SUM(Store_Name IS NULL) AS null_store_name,
    SUM(Store_City IS NULL) AS null_city,
    SUM(Store_Location IS NULL) AS null_location,
    SUM(Store_Open_Date IS NULL) AS null_open_date
FROM stores;

SELECT Store_ID, Product_ID, COUNT(*) AS cnt
FROM inventory
GROUP BY Store_ID, Product_ID
HAVING COUNT(*) > 1;

SELECT
    SUM(Store_ID IS NULL) AS null_store_id,
    SUM(Product_ID IS NULL) AS null_product_id,
    SUM(Stock_On_Hand IS NULL) AS null_stock
FROM inventory;

SELECT COUNT(*) AS negative_stock
FROM inventory
WHERE Stock_On_Hand < 0;

DESCRIBE sales;
DESCRIBE products;
DESCRIBE stores;
DESCRIBE inventory;

SELECT Date, COUNT(*) AS cnt
FROM sales
GROUP BY Date
ORDER BY Date
LIMIT 20;

SELECT
    SUM(Date LIKE '%/%') AS slash_format,
    SUM(Date LIKE '%-%') AS dash_format,
    SUM(Date IS NULL OR Date = '') AS missing_date
FROM sales;

SELECT Store_Open_Date, COUNT(*) AS cnt
FROM stores
GROUP BY Store_Open_Date
ORDER BY Store_Open_Date
LIMIT 20;

SELECT
    SUM(Store_Open_Date LIKE '%/%') AS slash_format,
    SUM(Store_Open_Date LIKE '%-%') AS dash_format,
    SUM(Store_Open_Date IS NULL OR Store_Open_Date = '') AS missing_date
FROM stores;

ALTER TABLE sales
MODIFY COLUMN Date DATE;
ALTER TABLE stores
MODIFY COLUMN Store_Open_Date DATE;