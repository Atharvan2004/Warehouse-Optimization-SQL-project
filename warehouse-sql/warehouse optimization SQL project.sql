-- ================================================================
-- Warehouse Optimization SQL Project
-- By Atharvan Pohnerkar
-- ================================================================

/*
1. Is there really a need to close the warehouse?
===============================================
*/

-- 1.1. Measuring Warehouse Space Utilization
-- See warehouse utilization statistics (capacity, current usage)
SELECT * FROM warehouses;

-- 1.2. Inventory Redundancy and Distribution
-- Are products stored in multiple warehouses?
SELECT productCode, COUNT(DISTINCT warehouseCode) AS cnt
FROM products
GROUP BY productCode
HAVING cnt > 1;

-- 1.3. Product Lines Across Warehouses
-- What product lines are stored in each warehouse?
SELECT DISTINCT productLine, warehouseCode
FROM products
ORDER BY warehouseCode;

-- 1.4. (Optional) Check if warehouse location is present
-- Would allow customer proximity analysis
SELECT * FROM warehouses;

-- 1.5. Order Quantity & Stock Analysis
-- Calculate order and stock info for each product
WITH t AS (
    SELECT o.orderNumber,
           p.productName,
           p.productLine,
           o.quantityOrdered * o.priceEach AS amt,
           o.quantityOrdered,
           p.quantityInStock,
           p.warehouseCode
    FROM orderdetails o
    JOIN products p ON o.productCode = p.productCode
)
SELECT
    t.productName,
    t.productLine,
    SUM(t.quantityOrdered) AS total_ordered,
    MAX(p.quantityInStock) AS quantity_in_stock,
    SUM(t.quantityOrdered)/MAX(p.quantityInStock) AS t_o_qis_ratio
FROM t
JOIN products p ON t.productName = p.productName
GROUP BY t.productName, t.productLine
ORDER BY t_o_qis_ratio DESC;

-- 1.6. (Optional) Vintage Cars Ratio Analysis
-- Find Vintage Cars with low demand vs stock
WITH t AS (
    SELECT o.orderNumber,
           p.productName,
           p.productLine,
           o.quantityOrdered,
           p.quantityInStock
    FROM orderdetails o
    JOIN products p ON o.productCode = p.productCode
)
SELECT
    t.productName,
    SUM(t.quantityOrdered) AS total_ordered,
    MAX(t.quantityInStock) AS quantity_in_stock,
    SUM(t.quantityOrdered)/MAX(t.quantityInStock) AS order_stock_ratio
FROM t
WHERE t.productLine = 'Vintage Cars'
GROUP BY t.productName
ORDER BY order_stock_ratio DESC;


/*
2. If a warehouse is closed, how should inventory be optimized?
==============================================================
*/

-- 2.1. Restocking High-Demand Products
-- Identify high-demand (total_ordered / in_stock > 0.8)
WITH t AS (
    SELECT o.orderNumber,
           p.productName,
           p.productLine,
           o.quantityOrdered,
           p.quantityInStock,
           p.warehouseCode
    FROM orderdetails o
    JOIN products p ON o.productCode = p.productCode
)
SELECT
    t.productName,
    t.productLine,
    SUM(t.quantityOrdered) AS total_ordered,
    MAX(t.quantityInStock) AS quantity_in_stock,
    SUM(t.quantityOrdered)/MAX(t.quantityInStock) AS ratio
FROM t
JOIN products p ON t.productName = p.productName
GROUP BY t.productName, t.productLine
ORDER BY t.productLine ASC, ratio DESC;

-- 2.2. Classic Cars Inventory Adjustment (<0.2 Over-Stocked)
-- (Example: Classic Cars with ratio <0.2)
-- Replace 'XXX' with cutoff ratio if needed
-- See previous query's output & filter as needed

-- 2.3. Vintage Cars Stock Reduction (<0.3 Over-Stocked)
-- (Example: Vintage Cars with ratio <0.3)
-- See previous query's output & filter as needed

-- 2.4. Total Units in Each Warehouse
SELECT warehouseCode, SUM(quantityInStock) AS total_units
FROM products
GROUP BY warehouseCode;

-- 2.5. Inventory Requirement Calculation Using Ideal Ratios
-- Assume temp_inventory_summary is a view/table generated above with columns:
-- productName, productLine, total_ordered, quantity_in_stock, ratio
SELECT
    productName,
    productLine,
    total_ordered,
    quantity_in_stock,
    ratio,
    CASE
        WHEN productLine = 'Vintage Cars' THEN ROUND(total_ordered / 0.18)
        WHEN productLine = 'Classic Cars' THEN ROUND(total_ordered / 0.30)
        ELSE quantity_in_stock
    END AS updated_inventory
FROM temp_inventory_summary
WHERE productLine IN ('Classic Cars', 'Vintage Cars')
ORDER BY productLine, updated_inventory DESC;

-- 2.6. Total Updated Inventory by ProductLine After Optimization
SELECT productLine, SUM(updated_inventory) AS total_optimized_inventory
FROM (
    SELECT
        productLine,
        CASE
            WHEN productLine = 'Vintage Cars' THEN ROUND(total_ordered / 0.18)
            WHEN productLine = 'Classic Cars' THEN ROUND(total_ordered / 0.30)
            ELSE quantity_in_stock
        END AS updated_inventory
    FROM temp_inventory_summary
    WHERE productLine IN ('Classic Cars', 'Vintage Cars')
) AS up
GROUP BY productLine;


/*
3. Optional: How to Ensure Same-Day Shipping After Closure?
===========================================================
*/

-- 3.1. Shipping Timelines for All Orders
SELECT orderNumber, orderDate, shippedDate,
       IFNULL(DATEDIFF(shippedDate, orderDate), 0) AS diff, comments
FROM orders
ORDER BY diff;

-- 3.2. Distribution of Shipping Days
SELECT diff, COUNT(diff) AS orders_count
FROM (
    SELECT orderNumber, orderDate, shippedDate, IFNULL(DATEDIFF(shippedDate, orderDate), 0) AS diff, comments
    FROM orders
) AS tt
GROUP BY diff
ORDER BY diff;

-- 3.3. Average Shipping Days by Product Line
SELECT
    p.productLine,
    ROUND(AVG(DATEDIFF(o.shippedDate, o.orderDate)), 2) AS avg_shipping_days
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.shippedDate IS NOT NULL
GROUP BY p.productLine
ORDER BY avg_shipping_days;

-- 3.4. Products/Lines with Frequent Shipping Delays (>3 Days)
SELECT
    p.productName,
    p.productLine,
    COUNT(*) AS delayed_orders,
    SUM(od.quantityOrdered) AS ordered,
    MAX(p.quantityInStock) AS inStock,
    p.warehouseCode
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE DATEDIFF(o.shippedDate, o.orderDate) > 3
GROUP BY p.productName, p.productLine, p.warehouseCode
ORDER BY delayed_orders DESC;

-- ================================
-- End of Warehouse Optimization SQL Project
-- ================================
