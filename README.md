# Warehouse-Optimization-SQL-project
!conveyor-belt-warehouse-concept-illustration_114360-17998.webp

# Warehouse Optimization SQL Project

**Author:** Atharvan Pohnerkar

Original Coursera Project - https://www.coursera.org/projects/showcase-analyze-data-model-car-database-mysql-workbench
Detailed analysis doc - https://docs.google.com/document/d/1Bc6u-P9brIQcbDQxHh-i1FPdWDVFv0Qd7Apdo7xDG8c/edit?usp=sharing

---

## Project Scenario

Mint Classics Company, a retailer of classic model cars, is considering closing one of their storage facilities.

The decision will be based on data-driven insights to:

- Reduce operational costs
- Optimize warehouse space usage
- Maintain customer delivery times

**Schema** - The Mint Classics relational database

!Screenshot 2025-08-08 095650.png

---

## Objectives

1. Explore products currently in inventory
2. Determine factors influencing inventory reorganization/reduction
3. Provide recommendations for warehouse closure

PowerBI dashboard - 

!image.png

!image.png

!image.png

## Step 1 – Assess the Need to Close a Warehouse

### 1. Check Warehouse Capacity

```sql
SELECT * FROM warehouses;
```

!Screenshot 2025-07-16 105147.png

**Insight:**

- Warehouse **West (c)** is at **50% capacity** → underutilized.

---

### 2. Check Inventory Redundancy

```sql

SELECT productCode, COUNT(DISTINCT warehouseCode) AS cnt
FROM products
GROUP BY productCode
HAVING cnt > 1;

```

!Screenshot 2025-07-16 105738.png

**Insight:**

- No redundancy → each product stored in **only one warehouse**.

---

### 3. Product Distribution by Warehouse

```sql

SELECT DISTINCT productLine, warehouseCode
FROM products
ORDER BY 2;

```

!Screenshot 2025-07-16 110244.png

**Insight:**

- Warehouse b → Classic Cars
- Warehouse c → Vintage Cars

---

### 4. Order Quantity vs Stock Ratio

```sql
WITH t AS (
    SELECT o.orderNumber, p.productName, p.productLine,
           o.quantityOrdered * o.priceEach AS amt,
           o.quantityOrdered, p.quantityInStock, p.warehouseCode
    FROM orderdetails o
    JOIN products p ON o.productCode = p.productCode
)
SELECT t.productName, t.productLine,
       SUM(t.quantityOrdered) AS total_ordered,
       MAX(p.quantityInStock) AS quantity_in_stock,
       SUM(t.quantityOrdered) / MAX(p.quantityInStock) AS 't.o/q.i.s'
FROM t
JOIN products p ON t.productName = p.productName
GROUP BY t.productName, t.productLine
ORDER BY 5 DESC;
```

!Screenshot 2025-07-16 112101.png

!Screenshot 2025-07-16 112438.png

**Insight:**

- Vintage Cars → very low demand (ratio mostly < 0.2).
- Only 3 Vintage Cars products have ratio > 1.
- Recommendation → Reduce Vintage Cars inventory significantly.

---

✅ **Conclusion:**

- Warehouse **c** (Vintage Cars) → Best candidate for closure.

---

## Step 2 – Plan Inventory Optimization After Closure

### 1. Identify Overstocked & Understocked Products

```sql
WITH t AS (
    SELECT o.orderNumber, p.productName, p.productLine,
           o.quantityOrdered * o.priceEach AS amt,
           o.quantityOrdered, p.quantityInStock, p.warehouseCode
    FROM orderdetails o
    JOIN products p ON o.productCode = p.productCode
)
SELECT t.productName, t.productLine,
       SUM(t.quantityOrdered) AS total_ordered,
       MAX(p.quantityInStock) AS quantity_in_stock,
       SUM(t.quantityOrdered) / MAX(p.quantityInStock) AS ratio
FROM t
JOIN products p ON t.productName = p.productName
WHERE t.productName in ("Vintage Cars", "Classic Cars")
GROUP BY t.productName, t.productLine
ORDER BY 2 ASC, 5 DESC;
```

!Screenshot 2025-07-16 144233.png

!Screenshot 2025-07-16 144431.png

**Insight:**

- Classic Cars → reduce stock for ratio < 0.3
- Vintage Cars → reduce stock for ratio < 0.3

---

### 2. Calculate Updated Inventory Needs

*Target Ratios:* Classic Cars → **0.30** Vintage Cars → **0.30**

```sql
SELECT
    productName,
    productLine,
    warehouseCode,
    total_ordered,
    quantity_in_stock,
    ratio,
    CASE
        WHEN ratio < 0.30 THEN ROUND(total_ordered / 0.30)
        WHEN ratio > 0.80 THEN ROUND(total_ordered / 0.80)
        ELSE quantity_in_stock
    END AS updated_inventory
FROM temp_inventory_summary
WHERE productLine IN ('Classic Cars', 'Vintage Cars')
ORDER BY
productLine,
updated_inventory DESC;
```

!Screenshot 2025-07-16 194433.png

!Screenshot 2025-07-16 191530.png

before

!image.png

after

**Insight:**

- After adjustment → Total inventory = 174k **units** (~53% of Warehouse b’s capacity).

---

✅ **Conclusion:**

- All stock fits into Warehouse b after optimization.

---

## Step 3 – Maintain Fast Shipping

### 1. Shipping Delay Analysis

```sql
SELECT diff, COUNT(diff)
FROM (
    SELECT orderNumber, orderDate, shippedDate,
           IFNULL(DATEDIFF(shippedDate, orderDate), 0) AS diff
    FROM orders
) AS tt
GROUP BY diff;
```

!Screenshot 2025-07-16 203255.png

**Insight:**

- Biggest improvement area → Orders with 3-6 **days delay**.

---

### 2. Average Shipping Time by Product Line

```sql
SELECT p.productLine,
       ROUND(AVG(DATEDIFF(o.shippedDate, o.orderDate)), 2) AS avg_shipping_days
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.shippedDate IS NOT NULL
GROUP BY p.productLine
ORDER BY avg_shipping_days;
```

!Screenshot 2025-07-17 185511.png

**Insight:**

- Ships → fastest
- Trains → slowest

---

### 3. Products with Frequent Delays

```sql
SELECT p.productName, p.productLine,
       COUNT(*) AS delayed_orders,
       SUM(od.quantityOrdered) AS ordered,
       MAX(p.quantityInStock) AS inStock,
       p.warehouseCode
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE DATEDIFF(o.shippedDate, o.orderDate) > 3
GROUP BY 1, 2, 6
ORDER BY delayed_orders DESC;
```

!Screenshot 2025-07-17 190544.png

**Insight:**

- Most delays → Warehouse a (Planes & Motorcycles).
- Focus on improving shipping process here.

---

## Final Recommendations

Based on the data-driven analysis conducted for Mint Classics Company, the following conclusions are drawn:

- Warehouse Closure:
    
    Warehouse ‘West’ (c) operates at only 50% of its capacity and exclusively stores Vintage Cars, which exhibit low demand relative to their current inventory levels. This makes it a strong candidate for closure without significantly impacting customer service levels.
    
- Inventory Optimization:
    
    Current inventory holdings, especially for Vintage Cars and select Classic Cars, are excessive relative to their sales volumes.
    
    By aligning inventory levels to target order-to-stock ratios (0.30 Vintage Cars and Classic Cars), significant space can be freed up in Warehouse ‘East’ (b).
    
    After redistribution and inventory reduction, the consolidated inventory from both warehouses will comfortably fit within the capacity of Warehouse ‘b’.
    
- Maintaining logistics:
    
    Analysis of current shipping timelines indicates that by focusing on reducing orders with 3-6 day processing times, shipping targets can be more consistently achieved. The analysis also indicates that Warehouse ‘d’ has highest average lead time, highlighting the need for shipping process optimization.
    

Overall, Mint Classics Company can move forward with the closure of Warehouse C, reduce excess inventory, and reorganize storage to maintain efficient operations and customer satisfaction.
