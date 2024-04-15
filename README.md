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
Expected column name(s): preferred_name
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
Return the customer_id and preferred name of customers 
who have made at least $2000 of purchases in parts that RevRoll did not install. 
Expected column names: customer_id, preferred_name

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

