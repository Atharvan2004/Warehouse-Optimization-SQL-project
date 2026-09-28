use mintclassics;
select * from orders;

CREATE VIEW v_fulfillment_analysis AS
SELECT 
    o.orderNumber,
    o.orderDate,
    o.shippedDate,
    DATEDIFF(o.shippedDate, o.orderDate) AS shipping_delay,
    p.productCode,
    p.productName,
    p.productLine,
    p.warehouseCode,
    od.quantityOrdered,
    o.status
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.shippedDate IS NOT NULL;

select  count( distinct orderNumber) from v_fulfillment_analysis;

DROP TEMPORARY TABLE IF EXISTS temp_inventory_summary;

CREATE TEMPORARY TABLE temp_inventory_summary AS
WITH t AS (
    SELECT
        p.productCode,
        p.productName,
        p.productLine,
        p.warehouseCode,
        od.quantityOrdered,
        p.quantityInStock
    FROM products p
    JOIN orderdetails od
        ON p.productCode = od.productCode
)

SELECT
    productCode,
    productName,
    productLine,
    warehouseCode,
    SUM(quantityOrdered) AS total_ordered,
    MAX(quantityInStock) AS quantity_in_stock,
    ROUND(
        SUM(quantityOrdered) / MAX(quantityInStock),
        3
    ) AS ratio
FROM t
GROUP BY
    productCode,
    productName,
    productLine,
    warehouseCode;