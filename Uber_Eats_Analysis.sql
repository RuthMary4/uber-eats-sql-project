--Uber Eats Data Analysis

SELECT * FROM customers;
SELECT * FROM restaurants; 
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

-- Checking Null Values 

-- Customers table
SELECT COUNT(*) FROM customers
WHERE
	customer_name IS NULL
	OR
	reg_date IS NULL

-- Restaurant table

SELECT COUNT(*) FROM restaurants
WHERE
	restaurant_name IS NULL
	OR
	city IS NULL
	OR
	opening_hours IS NULL

--Handling NULL Values

-- Orders table

SELECT * FROM orders
WHERE
	order_item IS NULL
	OR
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR
	total_amount IS NULL

DELETE FROM orders
WHERE
	order_item IS NULL
	OR
	order_date IS NULL
	OR
	order_time IS NULL
	OR
	order_status IS NULL
	OR
	total_amount IS NULL

INSERT INTO orders(order_id, customer_id, restaurant_id)
VALUES
(10002,2, 8),
(10003, 12, 21),
(10005, 27, 14);


-- -------------------------------------
-- Analysis & Reports
-- -------------------------------------

-- 1. Ordered Dishes by Customer:
-- Question: Write Query to find the ordered dishes by customer called "kate" for last 1 year.

SELECT 
	customer_name,
	dishes,
	total_orders
	
FROM -- table name
(SELECT
	c.customer_id,
	c.customer_name, 
	o.order_item as dishes,
	COUNT(*) as total_orders
FROM orders as o 
JOIN 
customers as c
ON c.customer_id = o.customer_id
WHERE
	o.order_date >= CURRENT_DATE - INTERVAL '1 Year'
	AND 
	c.customer_name = 'kate'
GROUP BY 1,2,3
ORDER BY 1,4 DESC) as t1


-- 2. Popular Time Slots:
-- Question: Identify the time slots during which the most orders are placed based on 2-hour intervals?

-- Approach 1
SELECT 
	CASE
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 and 1 THEN '00:00 - 02:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 and 3 THEN '02:00 - 04:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 and 5 THEN '04:00 - 06:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 and 7 THEN '06:00 - 08:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 and 9 THEN '08:00 - 10:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 and 11 THEN '10:00 - 12:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 and 13 THEN '12:00 - 14:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 and 15 THEN '14:00 - 16:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 and 17 THEN '16:00 - 18:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 and 19 THEN '18:00 - 20:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 and 21 THEN '20:00 - 22:00'
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 and 23 THEN '22:00 - 24:00'
	END AS time_slot,
	COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;

-- Approach 2
SELECT 
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT(HOUR FROM order_time)/2) + 2 as end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC


-- 3. Order Value Analysis:
-- Question: Find the average value per customer who has placed more than 2 orders. 
-- Return customer_name and AOV (average order value).

SELECT 
	c.customer_name,
	AVG(o.total_amount) as aov
FROM orders as o
	JOIN customers as c
	ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 2



--4. High-Value Customers:
-- Question: List the customers who have spent more than 1000$ in total on food orders. 
-- Return customer_name and customer_id.

SELECT 
	c.customer_name,
	SUM(o.total_amount) as total_spent
FROM orders as o
	JOIN customers as c
	ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 1000



-- 5. Orders without Delivery:
-- Question: Write a query to find orders that were placed but not delivered.
-- Return each restaurant name, city and number of not delivered orders.

-- Approach 1
SELECT 
	r.restaurant_name,
	COUNT(o.order_id) as cnt_not_delivered_orders
FROM orders as o
LEFT JOIN
restaurants as r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN 
deliveries as d
ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1

-- Approach 2
SELECT 	
	r.restaurant_name,
	COUNT(o.order_id) as cnt_not_delivered_orders
FROM orders as o
LEFT JOIN
restaurants as r
ON r.restaurant_id = o.restaurant_id
WHERE 
	o.order_id NOT IN (SELECT order_id FROM deliveries)
GROUP BY 1


-- 6. Restaurant Revenue Ranking:
-- Question: Rank restaurants by their total revenue from the last year, including their name, total revenue and rank within their city.

WITH ranking_table
AS
(
	SELECT 
		r.city,
		r.restaurant_name,
		SUM(o.total_amount) as revenue,
		RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) as rank
	FROM orders as o
	JOIN
	restaurants as r
	ON r.restaurant_id = o.restaurant_id
	GROUP BY 1, 2
)
SELECT
	*
FROM ranking_table
WHERE rank = 1



-- 7. Most Popular Dish by City:
-- Question: Identify the most popular dish in each city based on the number of orders.

SELECT *
FROM
(SELECT 
	r.city,
	o.order_item as dish,
	COUNT(order_id) as total_orders,
	RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_id) DESC) as rank
FROM orders as o
JOIN
restaurants as r
ON r.restaurant_id = o.restaurant_id
GROUP BY 1, 2
) as t1
WHERE rank = 1



-- 8. Customer Churn:
-- Question: Find the customers who haven't placed an order in the month of September but did in August of 2023.

SELECT DISTINCT customer_id FROM orders
WHERE
	EXTRACT(MONTH FROM order_date) = 08
	AND
	customer_id NOT IN
		(SELECT DISTINCT customer_id FROM orders
		WHERE EXTRACT(MONTH FROM order_date) = 09)



-- 9. Cancellation Rate Comparision:
-- Question: Calculate and compare the order cancellation rate for each restaurant between the September month and the August month.

WITH cancel_ratio_august
AS
(
    SELECT
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
	FROM orders as o
	LEFT JOIN
	deliveries as d
	ON o.order_id = d.order_id
	WHERE EXTRACT(MONTH FROM o.order_date) = 08
	GROUP BY 1
),
cancel_ratio_september
AS
(   SELECT
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
	FROM orders as o
	LEFT JOIN
	deliveries as d
	ON o.order_id = d.order_id
	WHERE EXTRACT(MONTH FROM o.order_date) = 09
	GROUP BY 1
),
august_month_data
AS
(
	SELECT 
		restaurant_id,
		total_orders,
		not_delivered,
		Round(
			not_delivered::numeric/total_orders::numeric * 100,
			2) as cancel_ratio
	FROM cancel_ratio_august
),
september_month_data
AS
(
	SELECT 
		restaurant_id,
		total_orders,
		not_delivered,
		Round(
			not_delivered::numeric/total_orders::numeric * 100,
			2) as cancel_ratio
	FROM cancel_ratio_september
)

SELECT 
	september_month_data.restaurant_id as rest_id,
	september_month_data.total_orders as cs_ratio ,
	september_month_data.cancel_ratio as sm_c_ratio
FROM september_month_data
JOIN
august_month_data
ON september_month_data.restaurant_id = august_month_data.restaurant_id



-- 10. Rider Average Delivery Time:
-- Question: Determine each rider's average delivery time.

SELECT 
	o.order_id,
	o.order_time,
	d.delivery_time,
	d.rider_id,
	d.delivery_time - o.order_time AS time_difference,
	EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
	CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	INTERVAL '0 day' END))/60 as time_difference_in_sec
FROM orders as o
JOIN deliveries AS d 
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';



-- 11. Monthly Restaurant Growth Rate:
-- Question: Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.

WITH growth_ratio
AS
(
SELECT
	o.restaurant_id,
	TO_CHAR(o.order_date, 'mm-yy') as month,
	COUNT(o.order_id) as cr_month_orders,
	LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) as prev_month_orders
FROM orders as o
JOIN
deliveries as d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY 1, 2
ORDER BY 1, 2
)
SELECT
	restaurant_id,
	month,
	prev_month_orders,
	cr_month_orders,
	ROUND (
	(cr_month_orders::numeric-prev_month_orders::numeric)/prev_month_orders::numeric * 100,
	2)
	as growth_ratio
FROM growth_ratio



-- 12. Customer Segmentation:
-- Question: Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value (AOV).
-- If a customer's total spending exceeds the AOV, label them as 'Gold'; otherwise, label them as 'Silver'. 
-- Write an SQL query to determine each segment's total number of orders and total revenue.

SELECT
cx_category,
SUM(total_orders) as total_orders,
SUM(total_spent) as total_revenue
FROM
	(SELECT
		customer_id,
		SUM(total_amount) as total_spent,
		COUNT(order_id) as total_orders,
		CASE
			WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
			ELSE 'silver'
		END as cx_category
	FROM orders
	group by 1
	) as t1
GROUP BY 1



-- 13. Rider Monthly Earnings:
-- Question: Calculate each rider's total monthly earnings, assuming they earn 8% of order amount.

SELECT
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') as month,
	SUM(total_amount) as revenue,
	SUM(total_amount) * 0.08 as riders_earning
FROM orders as o
JOIN deliveries as d
ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2



-- 14. Rider Ratings Analysis:
-- Question: Find the number of 5-star, 4-star, 3-star ratings each rider has. Riders recieve this ratings based on delivery time.
-- If orders are delivered less than 15 minutes of order recieved time the rider gets 5-star rating,
-- If they deliver in 15 and 20 minutes they get 4-star rating,
-- If they deliver after 20 minutes they get 3-star rating.

SELECT
	rider_id,
	stars,
	COUNT (*) as total_stars
FROM
(
	SELECT
		rider_id,
		delivery_took_time,
		CASE
			WHEN delivery_took_time < 15 THEN '5 star'
			WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4 star'
			ELSE '5 star'
		END as stars
		
	FROM
	(
		SELECT
			o.order_id,
			o.order_time,
			d.delivery_time,
			EXTRACT (EPOCH FROM (d.delivery_time - o.order_time +
			CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
			ELSE INTERVAL '0 day' END
			))/60 as delivery_took_time,
			d.rider_id
		FROM orders as o
		JOIN deliveries as d
		ON o.order_id = d.order_id
		WHERE delivery_status = 'Delivered'
	) as tl
) as t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC



-- 15. Order Frequency by Day:
-- Question: Analyze order frequency per day of the week and identify the peak day for each restaurant.

SELECT * FROM
(
	SELECT
		r.restaurant_name,
		TO_CHAR(o.order_date, 'Day') as day,
		COUNT(o.order_id) as total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) as rank
	FROM orders as o
	JOIN
	restaurants as r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
	) as t1
WHERE rank = 1



-- 16. Customer Life Value (CLV):
-- Question: Calculate the total revenue generated by each customer over all their orders. 

SELECT
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) as CLV
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY 1, 2



-- 17. Monthly sales Trends:
-- Question: Identify sales trends by comparing each month's total sales to the previous month.

SELECT
	EXTRACT(YEAR FROM order_date) as year,
	EXTRACT(MONTH FROM order_date) as month,
	SUM(total_amount) as total_sale,
	LAG(SUM(total_amount) , 1) OVER (ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date) ) as prev_month_sale
	FROM orders
GROUP BY 1, 2	



-- 18. Rider Efficiency:
-- Question: Evaluate the rider efficiency by determining the average delivery times and identifying those with lowest and highest averages.

WITH new_table
AS
(
	SELECT
		*,
		d.rider_id as riders_id,
		EXTRACT (EPOCH FROM (d.delivery_time - o.order_time +
		CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
		INTERVAL '0 day' END))/60 as time_deliver
	FROM orders as o
	JOIN deliveries as d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'
),
riders_time
AS
(
	SELECT
		riders_id,
		AVG(time_deliver) avg_time
	FROM new_table
	GROUP BY 1
)
SELECT
	MIN(avg_time),
	MAX(avg_time)
FROM riders_time



-- 19. Order Item Popularity:
-- Track the popularity of specific ordet items over time and identify seasonal spikes.

SELECT
	order_item,
	seasons,
	COUNT(order_id) as total_orders
FROM
(
SELECT
		*,
		EXTRACT(MONTH FROM order_date) as month,
		CASE
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
			WHEN EXTRACT(MONTH FROM order_date) > 6 AND
			EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
			ELSE 'Winter'
		END as seasons
	FROM orders
) as t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC



-- 20. Montly Restaurant Growth Rate:
-- Question: Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining.

SELECT
	r.city,
	SUM(total_amount) as total_revenue,
	RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN
restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1



--End--