select * from dim_customer;
-- 1  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
SELECT  
	DISTINCT market, 
    customer,
    region 
FROM dim_customer
WHERE customer="Atliq Exclusive" AND region="APAC"
ORDER BY market ASC;

-- 2 What is the percentage of unique product increase in 2021 vs. 2020? The  final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH cte1 AS (
	SELECT 
		COUNT(DISTINCT product_code) AS unique_product_2021 
	FROM fact_sales_monthly
	where fiscal_year= '2021'
),
cte2 AS (
	SELECT 
		COUNT(DISTINCT product_code) AS unique_product_2020 
	FROM fact_sales_monthly
	WHERE fiscal_year= '2020'
)
SELECT 
	cte1.unique_product_2021,cte2.unique_product_2020,
	ROUND((cte1.unique_product_2021-cte2.unique_product_2020)/cte2.unique_product_2020*100,2) AS percentage_chng 
FROM
cte1, cte2;

-- 3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains2 fields,segment
-- product_count
SELECT
	segment, 
    COUNT( DISTINCT product_code) AS product_count FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4 Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH cte1 AS (
SELECT 
	COUNT(DISTINCT fs.product_code) AS unique_product_2021, 
    dp.segment AS A
FROM fact_sales_monthly AS fs
JOIN dim_product AS dp
	ON  fs.product_code= dp.product_code
GROUP BY dp.segment,fs.fiscal_year
HAVING fiscal_year= 2021
),
cte2 AS (
SELECT 
	COUNT(DISTINCT fs.product_code) AS unique_product_2020, 	
    dp.segment AS B FROM fact_sales_monthly AS fs
JOIN dim_product AS dp
	ON  fs.product_code= dp.product_code
GROUP BY dp.segment,fs.fiscal_year
HAVING fiscal_year= 2020
)
SELECT 
	cte1.A,cte1.unique_product_2021,
    cte2.unique_product_2020,
	(cte1.unique_product_2021-cte2.unique_product_2020) AS difference
FROM cte1,cte2
WHERE cte1.A=cte2.B;

-- 5  Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

SELECT 
	m.product_code, 
    p.product,
    m.manufacturing_cost
FROM fact_manufacturing_cost AS m
JOIN  dim_product AS p
	ON m.product_code= p.product_code
WHERE manufacturing_cost IN (
SELECT MAX(manufacturing_cost) AS manufacturing_cost FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) AS manufacturing_cost FROM fact_manufacturing_cost
)
ORDER BY manufacturing_cost DESC;

-- 6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,customer_code. customer average_discount_percentage

SELECT 
	dm.customer_code,dm.customer,
	ROUND(AVG(pre_invoice_discount_pct),4) AS average_discount 
FROM fact_pre_invoice_deductions AS fd
JOIN  dim_customer AS dm
	ON fd.customer_code= dm.customer_code
GROUP BY dm.customer_code,dm.market,fd.fiscal_year,dm.customer
HAVING market='India' AND fiscal_year=2021
ORDER BY average_discount DESC 
LIMIT 5;

-- 7 . Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.The final report contains these columns: Month,Year,Gross sales Amount

SELECT
	MONTHNAME(fs.date) AS Month, 
    YEAR(fs.date) AS Year, 
    SUM(fg.gross_price*fs.sold_quantity) AS gross_sales_amount 
FROM dim_customer AS dm
JOIN fact_sales_monthly AS fs
	ON fs.customer_code= dm.customer_code
JOIN fact_gross_price AS fg
	ON fs.product_code= fg.product_code
WHERE dm.customer="Atliq Exclusive"
GROUP BY Month,Year
ORDER BY year;

-- 8  In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
-- Quarter total_sold_quantity

SELECT
	CASE
		WHEN MONTH(date) BETWEEN 9 AND 11 THEN "Q1"
		WHEN MONTH(date)=12 OR MONTH(date) BETWEEN 1 AND 2 THEN "Q2"
		WHEN MONTH(date) BETWEEN 3 AND 5 THEN "Q3"
		WHEN MONTH(date) BETWEEN 6 AND 8 THEN "Q4"
	END AS quarter,
		ROUND(SUM(sold_quantity )/1000000,2) AS total_sold_quantity 
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY quarter;

-- 9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
-- channel, gross_sales_mln,percentage

WITH cte AS (
		SELECT 
			dm.channel,
            SUM(fg.gross_price*fs.sold_quantity) AS total_sales 
		FROM dim_customer AS dm 
		JOIN fact_sales_monthly AS fs
          ON dm.customer_code=fs.customer_code
		JOIN fact_gross_price AS fg
		  ON fs.product_code= fg.product_code
		WHERE fs.fiscal_year=2021
		GROUP BY channel
)
	SELECT
		channel, 
		ROUND(total_sales/1000000,2) AS gross_sales_amount_mln,
		ROUND(total_sales/sum(total_sales) OVER()*100,2) AS percentage_contribution FROM cte
	ORDER BY percentage_contribution DESC
	LIMIT 1;
         
-- 10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,division, product_code,product,total_sold_quantity,rank_order.

WITH cte AS (
	SELECT 
		dm.division ,
		dm.product,	
        dm.product_code,	
        SUM(fs.sold_quantity) AS total_sold_quantity,
		RANK() OVER(PARTITION BY dm.division ORDER BY SUM(fs.sold_quantity) DESC) AS rank_order 
	FROM dim_product AS dm
	JOIN fact_sales_monthly AS fs
		ON dm.product_code=fs.product_code
	WHERE fs.fiscal_year=2021
	GROUP BY dm.division ,dm.product,dm.product_code
)
SELECT *FROM cte
WHERE rank_order IN (1,2,3);



