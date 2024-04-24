# Revroll-Company

## Project Overview
Revroll Company is an auto parts dealer and installer.
This data analysis project is aimed at assisting the RevRoll's management team to have a better knowledge of their customers' behavior and preferences and to analyse Employees' Performance in other to optimize their operations and improve overall business performance.

## Data Sources
Please refer to the attached Microsoft Word document for the Entity Relationship Diagram and Data Dictionary

## Tools
- Postgres SQL - Used for data analysis
- Tableau - Used for data visualization
- Microsoft Excel - To calculate the pearson correlation coeficient to determine the strength of the linear relationship between the number of installations and the total value of parts installed by each installer
## Data Analysis
The following questions were answered using POSTGRESQL to provide useful insights on Revroll customers and staff(installers)

1. what is the relationship between the number of installations and the total value of parts installed by each installer?
*first, write a query to find the total number of installs, and total value of installs grouped by installer
*Then visualize the data above in tableau (see attached file)
*Finally, calculate the pearson correlation coeficient to determine the strength of association between the variables of interest.(see attached file)

```sql
SELECT 
	installers.name, 
   	COUNT(install_id) AS no_of_installation, 
    	SUM(quantity*price) AS total_value_of_parts_installed, 
	RANK() OVER (ORDER BY COUNT(install_id) DESC) AS total_installation_rank, 
    	RANK() OVER (ORDER BY SUM(quantity*price) DESC) AS total_value_rank

FROM 
	installs
JOIN 
	orders ON installs.order_id = orders.order_id
JOIN 
	parts ON orders.part_id = parts.part_id
JOIN
	installers ON installers.installer_id = installs.installer_id
		
GROUP BY
	installers.name;
```

2. Write a query to find the customer(s) with the most orders.   
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
3. RevRoll does not install every part that is purchased. Some customers prefer to install parts themselves. Return the `customer_id` and `preferred name` of customers who have made at least $2000 of purchases in parts that RevRoll did not install. 
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
4.Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter, so as to recommend to these customers to buy an Air Filter.
Return the result table ordered by `customer_id`
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
5.RevRoll encourages healthy competition. The company holds an Install Derby where installers face off to see who can change a part the fastest in a tournament style contest.

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
6. Find the fastest install time with its corresponding `derby_id` for each installer. 
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
```
#### Note: Kindly refer to the attached SQL file for more questions and answers.

## Results and Recommendations
1. Customer(s) with the most orders can be given exclusive discounts and loyalty rewards,their feedbacks could also be sought so that there is a better understanding of what aspect of the business( products or servcies) appeals to them.

2. By finding out how many of their customers prefer to self install the parts they purchased, the management team could decide to offer them DIY installation kits and comprehensive guides for those parts. This will encourage even more customers to self install and potentially increase sales.

3. Installers with the highest scores and fastest install times can be acknowledged for their skills and contributions. This will help to boost morale and motivation among installers.
installers who also need additional training or support can be identified as well and training programs and workshops could be organized to assist thenm in other to improve  their skills and efficiency in installations.


