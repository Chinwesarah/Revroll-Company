/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.

Expected column names: name, bonus
*/


WITH parts_installed_table AS (
    SELECT 
        installers.name, 
        installs.install_id, 
        orders.part_id, 
        parts.price, 
        orders.quantity
    FROM 
        installers
    LEFT JOIN 
        installs ON installers.installer_id = installs.installer_id
    LEFT JOIN 
        orders ON installs.order_id = orders.order_id
    LEFT JOIN 
        parts ON orders.part_id = parts.part_id
)
SELECT 
    "name", 
    ROUND(SUM(price * quantity) * 0.1) AS bonus
FROM 
    parts_installed_table
GROUP BY 
    "name"
ORDER BY 
    bonus ASC;


/*
Question #2: 
Write a solution to calculate the�total parts spending�by customers paying for installs on�each Friday�of�every week�in�November 2023. 
If there are�no�purchases on the�Friday of a particular week, the parts total should be set to�`0`.

Return�the result table ordered by week of month�in�ascending�order.

Expected column names: `november_fridays`, `parts_total`
*/


WITH newtable AS (
    SELECT 
        install_id, 
        installs.order_id, 
        installs.install_date, 
        orders.part_id, 
        COALESCE((orders.quantity * parts.price), 0) AS total_price
    FROM 
        installs
    LEFT JOIN 
        orders ON orders.order_id = installs.order_id
    LEFT JOIN 
        parts ON parts.part_id = orders.part_id
    WHERE 
        EXTRACT(MONTH FROM install_date) = 11 
        AND EXTRACT(DOW FROM install_date) = 5
)
SELECT 
    install_date AS november_fridays, 
    SUM(total_price) AS parts_total
FROM 
    newtable
GROUP BY 
    november_fridays;

/*
Question #3: 
Write a solution to find the�third transaction of every customer, where the�spending�on the preceding�two transactions�is�lower�than the spending on the�third�transaction. 
Only consider transactions that include an installation, and return�the result table by�`customer_id`�in�ascending�order.

Expected column names: `customer_id`, `third_transaction_spend`, `third_transaction_date`
*/

WITH newtable AS (
    SELECT
        orders.order_id,
        orders.customer_id,
        installs.install_id,
        installs.install_date,
        orders.quantity * parts.price AS transaction_spend
    FROM
        orders
    INNER JOIN
        installs ON installs.order_id = orders.order_id
    INNER JOIN
        parts ON parts.part_id = orders.part_id
    ORDER BY
        orders.customer_id,
        installs.install_date
),
ranking_table AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY install_date, transaction_spend DESC) AS rank
    FROM
        newtable
),
LAG_table AS (
    SELECT
        *,
        LAG(transaction_spend, 1) OVER (PARTITION BY customer_id ORDER BY install_date) AS first_transaction,
        LAG(transaction_spend, 2) OVER (PARTITION BY customer_id ORDER BY install_date) AS second_transaction
    FROM
        ranking_table
    WHERE
        rank IN (1, 2, 3)
)
SELECT
    customer_id,
    transaction_spend AS third_transaction_spend,
    install_date AS third_transaction_date
FROM
    LAG_table
WHERE
    rank = 3
    AND first_transaction < transaction_spend
    AND second_transaction < transaction_spend;

/*
Question #4: 
Write a query to find the installers who have completed installations for at least four consecutive days. 
Include the�`installer_id`,start date of the consecutive installations period and the end date of the consecutive installations period. 

Return�the result table ordered by`installer_id`in �ascending�order.

Expected column names: `installer_id`, `consecutive_start`, `consecutive_end`
*/

WITH CTE1 AS (
    SELECT 
        *,
        LAG(install_date) OVER(PARTITION BY installer_id ORDER BY install_date) AS pre_install_date
    FROM 
        installs
    ORDER BY
        installer_id, install_date
),
CTE2 AS (
    SELECT 
        installer_id,
        install_date,
        COALESCE(pre_install_date, install_date) AS pre_install_date,
        install_date - INTERVAL '1 day' * (ROW_NUMBER() OVER(PARTITION BY installer_id ORDER BY install_date)) AS GRP,
        (ROW_NUMBER() OVER(PARTITION BY installer_id ORDER BY install_date)) AS rn
    FROM 
        CTE1 
    WHERE 
        install_date - pre_install_date = 1
)
SELECT 
    installer_id,
    MIN(pre_install_date) AS consecutive_start,
    MAX(install_date) AS consecutive_end
FROM 
    CTE2
GROUP BY 
    installer_id, GRP
HAVING 
    COUNT(GRP) > 2;



