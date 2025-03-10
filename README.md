# Revroll-Company  

Revroll Company is an auto parts dealer and installer. 

## Project Overview
This data analysis project is aimed at assisting the RevRoll's management team to have a better knowledge of their customers' behavior and preferences and to analyse employees' performance in other to optimize their operations and improve overall business performance.

## Data Sources
1. Please refer to the attached Microsoft Word document for the Entity Relationship Diagram and Data Dictionary
2. Pearson correlation coeficient calculation: https://docs.google.com/spreadsheets/d/1A3QI3Wc6DvReGsapNpEUFpWV5KhgV6ak_TxSndpZ1dg/edit?usp=drive_link
3. Tableau visualization: https://public.tableau.com/views/No_ofinstallationsVs_Totalvalueofpartsinstalledperinstaller/Sheet1?:language=en-GB&publish=yes&:sid=&:display_count=n&:origin=viz_share_link


## Tools
- Postgres SQL - Used for data analysis
- Tableau - Used for data visualization
- Google spreadsheet - To calculate the pearson correlation coeficient to determine the strength of the linear relationship between the number of installations and the total value of parts installed by each installer
  
## Data Analysis
The following questions were answered using POSTGRESQL to provide useful insights on Revroll customers and staff(installers)

**Question 1.** what is the relationship between the number of installations and the total value of parts installed by each installer?

*first, write a query to find the total number of installs, and total value of installs grouped by installer
*Then visualize the data above in tableau
*Finally, calculate the pearson correlation coeficient to determine the strength of association between the variables of interest  

**Query explanation:**  
1. The query selects the name of the installers, the count of installation IDs, and a new column which is the total value of parts installed (this is calculated by multiplying the quantity of parts by their price and summing up the resul)
2. The installs, orders, parts and installers tables are joined to fetch the necessary data
3. Finally, the result is grouped by installers name, which means the aggregate functions (COUNT and SUM) will be applied for each installer individually.

```sql
SELECT 
	installers.name, 
   	COUNT(install_id) AS no_of_installation, 
    	SUM(quantity*price) AS total_value_of_parts_installed
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

**Question 2.** Write a query to find the customer(s) with the most orders.   
Expected column name(s): `preferred_name`

**Query Explanation:**  
1. The CTE(Newtable) created selects customer_id, no_of_orders(derived from The count of orders placed by each customer) and preferred_name for each customer.
2. The orders table is joined with the customers table using LEFT JOIN to get the necessary data.
3. The LEFT JOIN ensures that all customers are included, even those with zero orders.
4. Results are then grouped by customer Id and preferred_name, so that the aggregated column (no_of_orders) will be applied to each customer.
5. From the CTE (newtable) created, the preferred_name is then selected and a WHERE clause is used to filter customer(s) with the highest number of orders.
6. A subquery is used to enable the use of an aggregate function (MAX), since we cannot directly use an aggregate function with a WHERE clause.
   
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
**Question 3.** RevRoll does not install every part that is purchased. Some customers prefer to install parts themselves. Return the `customer_id` and `preferred name` of customers who have made at least $2000 of purchases in parts that RevRoll did not install. 
Expected column names: `customer_id`, `preferred_name`  

**Query Explanation:**  
1. The query selects customer_id and preferred_name from the customers table
2. The query uses multiple LEFT JOIN operations to combine data from the customers, orders, parts, and installs tables
3. the WHERE clause filters out customers that haven't had any installation (as indicated by installs.order_id IS NULL).
4. The HAVING clause filters out customers that have made less than $2000 of purchase (as indicated by SUM(parts.price * orders.quantity) >= 2000)
5. Results are grouped by customer_id and preferred_name

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
**Question 4.** Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter, so as to recommend to these customers to buy an Air Filter.
Return the result table ordered by `customer_id`  

**Query Explanation:**  
1. The query selects customer_id and preferred_name from the customers table and JOINS the orders table on customer_id
2. In the WHERE clause, each subquery filters customers that purchased or did not purchase the part with the part_id listed, this is achieved using the IN and NOT IN operators
3. The AND operator in the WHERE clause is used so that only customers that meet all three conditions are returned.
4. The results are then ordered by customer_id.

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
**Question 5.** RevRoll encourages healthy competition. The company holds an Install Derby where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by installer_id in increasing order.
Expected column names: `installer_id`, `name`, `num_points`  

**Query Explanation:**  
1. The first CTE (score_table) selects columns installer_one_id,installer_two_id (the 2 installers involved in each competition)
2. 2 CASE statements are used to create 2 additional columns (installer_one_score and installer_two_score columns) which are the scores awarded to each installer in a competition
3. The second CTE (stack_column) selects installer_one_id and  installer_one_score from the score_table and uses the UNION ALL operator to combine scores from both installer_one_id and installer_two_id into a single column format.
4. The final query joins the stack_column table with the installers table to map installer IDs to their names. It then calculates the total score (num_points) for each installer by summing their points from stack_column_table.
5. The COALESCE function ensures that installer(s) with no scores(did not participate in the competion and therefore not included in the install_derby table but are on the table that has the names of all installers, that is the installers table) are assigned 0 points.
6. The results are grouped by installer ID and name, then ordered by total points in descending order.
   
```sql
WITH score_table AS (
    SELECT 
        installer_one_id,
        installer_two_id,
        CASE 
            WHEN installer_one_time < installer_two_time THEN 3 
            WHEN installer_one_time = installer_two_time THEN 1 
            ELSE 0 
        END AS installer_one_score,
        CASE 
            WHEN installer_two_time < installer_one_time THEN 3 
            WHEN installer_one_time = installer_two_time THEN 1 
            ELSE 0 
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
**Question 6.** Find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order. 

**Query Explanation:**  

1. The first CTE (stack_table) is constructed by combining the columns from install_derby using UNION ALL. Each row in the install_derby table produces two rows in stack_table, one for each installer (installer_one_id and installer_two_id) with their corresponding times (installer_one_time and installer_two_time).The resulting stack_table has three columns: derby_id, installer_id, and installer_time.
2. The second CTE (rank_table) is generated by adding a rank to each row in stack_table. The ranking is done within each partition of installer_id, ordered by installer_time and then by derby_id.
3. The rank is calculated using the RANK() window function.
4. The final query extracts the derby_id, installer_id, and installer_time from rank_table where the rank is 1. This ensures that only the row with the earliest installer_time for each installer_id is selected.

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
1. The Pearson correlation coefficient for the relationship between the number of installations and the total value of parts installed by each installer is **0.3** which indicates a low positive relationship.

2. Customer(s) with the most orders can be given exclusive discounts and loyalty rewards,their feedbacks could also be sought so that there is a better understanding of what aspect of the business( products or servcies) appeals to them.

3. By finding out how many of their customers prefer to self install the parts they purchased, the management team could decide to offer them DIY installation kits and comprehensive guides for those parts. This will encourage even more customers to self install and potentially increase sales.

4. Installers with the highest scores and fastest install times can be acknowledged for their skills and contributions. This will help to boost morale and motivation among installers.
installers who also need additional training or support can be identified as well and training programs and workshops could be organized to assist them in other to improve  their skills and efficiency in installations.


