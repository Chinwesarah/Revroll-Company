# Revroll-Company

## Project Overview
Revroll Company is an auto parts dealer and installer.
This data analysis project is aimed at  assising the RevRoll's management team to have a better knowledge of their customers' behavior and preferences and to analyse Employees' Performance in other to optimize their operations and improve overall business performance.

## Data Sources
Please refer to the attached Microsoft Word document for the Entity Relationship Diagram and Data Dictionary

## Tools
- Postgres SQL - Used for data analysis
- Tableau - Data Visualization and storytelling
## Data Analysis
The following questions were answered using POSTGRESQL to provide useful insights on Revroll customers and staff(installers)
1. Write a query to find the customer(s) with the most orders.   
Expected column name(s): `preferred_name`
```sql
WITH newtable AS (
    SELECT 
        customers.customer_id, 
        COUNT(order_id) AS no_of_orders, 
        preferred_name
    FROM 
        orders
    LEFT JOIN 
        customers ON customers.customer_id = orders.customer_id
    GROUP BY 
        customers.customer_id, 
        preferred_name
)

SELECT 
    preferred_name
FROM 
    newtable
WHERE 
    no_of_orders = (SELECT MAX(no_of_orders) FROM newtable);
```
2. RevRoll does not install every part that is purchased. 
Some customers prefer to install parts themselves. 
This is a valuable line of business 
RevRoll wants to encourage this by finding valuable self-install customers and sending them offers.
Return the customer_id and preferred name of customers who have made at least $2000 of purchases in parts that RevRoll did not install. 
Expected column names: `customer_id`, `preferred_name`

```sql
SELECT 
		customers.customer_id, 
    customers.preferred_name
FROM 
		customers 
LEFT JOIN 
		orders ON customers.customer_id = orders.customer_id
LEFT JOIN 
		parts ON orders.part_id = parts.part_id
LEFT JOIN 
		installs ON orders.order_id = installs.order_id
WHERE 
		installs.order_id IS NULL
GROUP BY 
		customers.customer_id, 
    customers.preferred_name
HAVING 
		SUM(parts.price * orders.quantity) >= 2000;
```
3.Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter, Return the result table ordered by `customer_id`
```sql
SELECT DISTINCT
	customers.customer_id, 
  customers.preferred_name
FROM 
	customers 
JOIN
	orders 
ON
	customers.customer_id = orders.customer_id
	
where customers.customer_id IN (SELECT customer_id FROM orders WHERE part_id = 19)
and customers.customer_id IN (SELECT customer_id FROM orders WHERE part_id = 2)
and customers.customer_id NOT IN (SELECT customer_id FROM orders WHERE part_id = 3)
order by customers.customer_id;
```
4.RevRoll encourages healthy competition. The company holds an Install Derby where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by installer_id in increasing order.
Expected column names: `installer_id`, `name`, `num_points`
```sql
WITH score_table AS (
    SELECT 
        installer_one_id,
        installer_two_id,
        CASE 
            WHEN installer_one_time < installer_two_time THEN 3 
            ELSE 
                CASE 
                    WHEN installer_one_time = installer_two_time THEN 1 
                    ELSE 0 
                END 
        END AS installer_one_score,
        CASE 
            WHEN installer_two_time < installer_one_time THEN 3 
            ELSE 
                CASE 
                    WHEN installer_one_time = installer_two_time THEN 1 
                    ELSE 0 
                END 
        END AS installer_two_score
    FROM 
        install_derby
),

stack_column_table AS (
    SELECT 
        installer_one_id AS installer_id, 
        installer_one_score AS installer_score
    FROM 
        score_table
    UNION ALL
    SELECT 
        installer_two_id, 
        installer_two_score
    FROM 
        score_table
)

SELECT 
    installers.installer_id,
    "name", 
    COALESCE(SUM(installer_score), 0) AS num_points
FROM 
    stack_column_table
RIGHT JOIN 
    installers ON stack_column_table.installer_id = installers.installer_id
GROUP BY 
    installers.installer_id, 
    "name"
ORDER BY 
    num_points DESC;
```
5. Find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order.

```sql
WITH stack_table AS (
    SELECT 
        derby_id, 
        installer_one_id AS installer_id, 
        installer_one_time AS installer_time
    FROM 
        install_derby
    UNION ALL
    SELECT 
        derby_id, 
        installer_two_id, 
        installer_two_time
    FROM 
        install_derby
),
rank_table AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY installer_id ORDER BY installer_time, derby_id) AS rank
    FROM 
        stack_table
)

SELECT 
    derby_id, 
    installer_id, 
    installer_time
FROM 
    rank_table
WHERE 
    rank = 1;



