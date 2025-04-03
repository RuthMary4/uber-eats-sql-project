# Uber Eats Data Analysis using SQL  

## **Database Schema Setup**  

This project involves analyzing Uber Eats data using SQL. The database consists of five main tables:  
- **customers** (stores customer details)  
- **restaurants** (stores restaurant details)  
- **orders** (stores customer orders)  
- **riders** (stores rider details)  
- **deliveries** (stores delivery status and assignments)  

---


```sql
-- Drop tables if they exist to avoid conflicts
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS riders;
DROP TABLE IF EXISTS deliveries;

-- Create Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25),
    reg_date DATE
);

-- Create Restaurants Table
CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(55),
    city VARCHAR(15),
    opening_hours VARCHAR(55)
);

-- Create Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT, -- Foreign key from customers table
    restaurant_id INT, -- Foreign key from restaurants table
    order_item VARCHAR(55),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(55),
    total_amount FLOAT
);

-- Adding Foreign Key Constraints for Orders Table
ALTER TABLE orders
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_restaurants
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(restaurant_id);

-- Create Riders Table
CREATE TABLE riders (
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(55),
    sign_up DATE
);

-- Create Deliveries Table
CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY,
    order_id INT, -- Foreign key from orders table
    delivery_status VARCHAR(35),
    delivery_time TIME,
    rider_id INT, -- Foreign key from riders table
    CONSTRAINT fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_riders FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);

## **SQL Script**  

```sql
-- Exploratory Data Analysis  

SELECT * FROM customers;
SELECT * FROM restaurants; 
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

-- Checking Null Values  

-- Customers Table
SELECT COUNT(*) FROM customers
WHERE
    customer_name IS NULL
    OR reg_date IS NULL;

-- Restaurants Table
SELECT COUNT(*) FROM restaurants
WHERE
    restaurant_name IS NULL
    OR city IS NULL
    OR opening_hours IS NULL;

-- Handling NULL Values  

-- Orders Table: Identifying NULL values  
SELECT * FROM orders
WHERE
    order_item IS NULL
    OR order_date IS NULL
    OR order_time IS NULL
    OR order_status IS NULL
    OR total_amount IS NULL;

-- Deleting Rows with NULL values in Orders Table  
DELETE FROM orders
WHERE
    order_item IS NULL
    OR order_date IS NULL
    OR order_time IS NULL
    OR order_status IS NULL
    OR total_amount IS NULL;

-- Inserting Sample Data into Orders Table  
INSERT INTO orders(order_id, customer_id, restaurant_id)
VALUES
    (10002, 2, 8),
    (10003, 12, 21),
    (10005, 27, 14);

```sql
-- -------------------------------------
-- Analysis & Reports
-- -------------------------------------

-- 1. Ordered Dishes by Customer  
-- Find the dishes ordered by customer "Kate" in the last year.  

SELECT 
    customer_name,
    dishes,
    total_orders
FROM 
    (SELECT 
        c.customer_id,
        c.customer_name, 
        o.order_item AS dishes,
        COUNT(*) AS total_orders
    FROM orders AS o 
    JOIN customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 Year'
    AND c.customer_name = 'Kate'
    GROUP BY 1,2,3
    ORDER BY 1,4 DESC) AS t1;


-- 2. Popular Time Slots  
-- Identify time slots with the most orders placed using 2-hour intervals.  

-- Approach 1  
SELECT 
    CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 24:00'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;

-- Approach 2  
SELECT 
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,
    FLOOR(EXTRACT(HOUR FROM order_time)/2) + 2 AS end_time,
    COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC;


-- 3. Order Value Analysis  
-- Find the average order value (AOV) per customer with more than 2 orders.  

SELECT 
    c.customer_name,
    AVG(o.total_amount) AS aov
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 2;


-- 4. High-Value Customers  
-- Identify customers who have spent more than $1000 on food orders.  

SELECT 
    c.customer_name,
    SUM(o.total_amount) AS total_spent
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 1000;


-- 5. Orders Without Delivery  
-- Find orders that were placed but not delivered.  

-- Approach 1  
SELECT 
    r.restaurant_name,
    COUNT(o.order_id) AS cnt_not_delivered_orders
FROM orders AS o
LEFT JOIN restaurants AS r ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries AS d ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1;

-- Approach 2  
SELECT 
    r.restaurant_name,
    COUNT(o.order_id) AS cnt_not_delivered_orders
FROM orders AS o
LEFT JOIN restaurants AS r ON r.restaurant_id = o.restaurant_id
WHERE o.order_id NOT IN (SELECT order_id FROM deliveries)
GROUP BY 1;


-- 6. Restaurant Revenue Ranking  
-- Rank restaurants by total revenue from the last year.  

WITH ranking_table AS (
    SELECT 
        r.city,
        r.restaurant_name,
        SUM(o.total_amount) AS revenue,
        RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
    FROM orders AS o
    JOIN restaurants AS r ON r.restaurant_id = o.restaurant_id
    GROUP BY 1, 2
)
SELECT * FROM ranking_table WHERE rank = 1;


-- 7. Most Popular Dish by City  
-- Identify the most ordered dish in each city.  

SELECT *
FROM (
    SELECT 
        r.city,
        o.order_item AS dish,
        COUNT(order_id) AS total_orders,
        RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_id) DESC) AS rank
    FROM orders AS o
    JOIN restaurants AS r ON r.restaurant_id = o.restaurant_id
    GROUP BY 1, 2
) AS t1
WHERE rank = 1;


-- 8. Customer Churn  
-- Find customers who placed orders in August 2023 but not in September 2023.  

SELECT DISTINCT customer_id FROM orders
WHERE EXTRACT(MONTH FROM order_date) = 08
AND customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
    WHERE EXTRACT(MONTH FROM order_date) = 09
);


-- 9. Cancellation Rate Comparison  
-- Compare order cancellation rates for each restaurant in August vs September.  

WITH cancel_ratio_august AS (
    SELECT
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE EXTRACT(MONTH FROM o.order_date) = 08
    GROUP BY 1
),
cancel_ratio_september AS (
    SELECT
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE EXTRACT(MONTH FROM o.order_date) = 09
    GROUP BY 1
),
august_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_august
),
september_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_september
)
SELECT 
    september_data.restaurant_id AS rest_id,
    september_data.total_orders AS cs_ratio,
    september_data.cancel_ratio AS sm_c_ratio
FROM september_data
JOIN august_data ON september_data.restaurant_id = august_data.restaurant_id;


-- 10. Rider Average Delivery Time  
-- Calculate each rider’s average delivery time.  

SELECT 
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    d.delivery_time - o.order_time AS time_difference,
    EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
        CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END)) / 60 AS time_difference_in_sec
FROM orders AS o
JOIN deliveries AS d ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';

-- 11. Monthly Restaurant Growth Rate
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.

WITH growth_ratio AS (
    SELECT
        o.restaurant_id,
        TO_CHAR(o.order_date, 'mm-yy') AS month,
        COUNT(o.order_id) AS cr_month_orders,
        LAG(COUNT(o.order_id), 1) OVER (PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) AS prev_month_orders
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY 1, 2
)
SELECT
    restaurant_id,
    month,
    prev_month_orders,
    cr_month_orders,
    ROUND(
        (cr_month_orders::numeric - prev_month_orders::numeric) / prev_month_orders::numeric * 100,
        2
    ) AS growth_ratio
FROM growth_ratio;

-- 12. Customer Segmentation
-- Categorize customers into 'Gold' or 'Silver' groups based on total spending vs. AOV.

SELECT
    cx_category,
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue
FROM (
    SELECT
        customer_id,
        SUM(total_amount) AS total_spent,
        COUNT(order_id) AS total_orders,
        CASE
            WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
            ELSE 'Silver'
        END AS cx_category
    FROM orders
    GROUP BY 1
) AS t1
GROUP BY 1;

-- 13. Rider Monthly Earnings
-- Calculate each rider's monthly earnings, assuming they earn 8% of order amount.

SELECT
    d.rider_id,
    TO_CHAR(o.order_date, 'mm-yy') AS month,
    SUM(total_amount) AS revenue,
    SUM(total_amount) * 0.08 AS riders_earning
FROM orders AS o
JOIN deliveries AS d ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- 14. Rider Ratings Analysis
-- Analyze rider ratings based on delivery times.

SELECT
    rider_id,
    stars,
    COUNT(*) AS total_stars
FROM (
    SELECT
        rider_id,
        CASE
            WHEN delivery_took_time < 15 THEN '5 star'
            WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4 star'
            ELSE '3 star'
        END AS stars
    FROM (
        SELECT
            d.rider_id,
            EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
                CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
            )) / 60 AS delivery_took_time
        FROM orders AS o
        JOIN deliveries AS d ON o.order_id = d.order_id
        WHERE d.delivery_status = 'Delivered'
    ) AS tl
) AS t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- 15. Order Frequency by Day
-- Identify the peak order day for each restaurant.

SELECT * FROM (
    SELECT
        r.restaurant_name,
        TO_CHAR(o.order_date, 'Day') AS day,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER (PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rank
    FROM orders AS o
    JOIN restaurants AS r ON o.restaurant_id = r.restaurant_id
    GROUP BY 1, 2
) AS t1
WHERE rank = 1;

-- 16. Customer Lifetime Value (CLV)
-- Calculate total revenue generated by each customer.

SELECT
    o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS CLV
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY 1, 2;

-- 17. Monthly Sales Trends
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(total_amount) AS total_sale,
    LAG(SUM(total_amount), 1) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS prev_month_sale
FROM orders
GROUP BY 1, 2;

-- 18. Rider Efficiency
-- Evaluate rider efficiency by determining average delivery times.

WITH new_table AS (
    SELECT
        d.rider_id AS riders_id,
        EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
            CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE INTERVAL '0 day' END
        )) / 60 AS time_deliver
    FROM orders AS o
    JOIN deliveries AS d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
riders_time AS (
    SELECT
        riders_id,
        AVG(time_deliver) AS avg_time
    FROM new_table
    GROUP BY 1
)
SELECT
    MIN(avg_time) AS min_avg_time,
    MAX(avg_time) AS max_avg_time
FROM riders_time;

-- 19. Order Item Popularity
-- Track the popularity of specific order items over time and identify seasonal spikes.

SELECT
    order_item,
    seasons,
    COUNT(order_id) AS total_orders
FROM (
    SELECT
        order_item,
        CASE
            WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
            WHEN EXTRACT(MONTH FROM order_date) BETWEEN 7 AND 9 THEN 'Summer'
            ELSE 'Winter'
        END AS seasons
    FROM orders
) AS t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- 20. Monthly Restaurant Growth Rate
-- Calculate revenue growth per city and rank cities based on revenue.

SELECT
    r.city,
    SUM(total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(total_amount) DESC) AS city_rank
FROM orders AS o
JOIN restaurants AS r ON o.restaurant_id = r.restaurant_id
GROUP BY 1;

-- End --
