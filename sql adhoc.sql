select * from dim_customer;
-- 1  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
select distinct market, customer,region from dim_customer
where customer="Atliq Exclusive" AND region="APAC"
order by market asc;

-- 2 What is the percentage of unique product increase in 2021 vs. 2020? The  final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH cte1 as(
select count(distinct product_code) as unique_product_2021 from fact_sales_monthly
where fiscal_year= '2021'
),
cte2 as(
select count(distinct product_code) as unique_product_2020 from fact_sales_monthly
where fiscal_year= '2020'
)
select cte1.unique_product_2021,cte2.unique_product_2020,
Round((cte1.unique_product_2021-cte2.unique_product_2020)/cte2.unique_product_2020*100,2) as percentage_chng 
from 
cte1
cross join cte2;

-- 3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains2 fields,segment
-- product_count
select segment, count( distinct product_code) as product_count from dim_product
group by segment
order by product_count desc;

-- 4 Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH cte1 as (
select count(distinct fs.product_code) as unique_product_2021, dp.segment as A from fact_sales_monthly as fs
join dim_product as dp
on  fs.product_code= dp.product_code
group by dp.segment,fs.fiscal_year
having fiscal_year= 2021
),
cte2 as(
select count(distinct fs.product_code) as unique_product_2020 , dp.segment as B from fact_sales_monthly as fs
join dim_product as dp
on  fs.product_code= dp.product_code
group by dp.segment,fs.fiscal_year
having fiscal_year= 2020
)
select cte1.A,cte1.unique_product_2021,cte2.unique_product_2020,
(cte1.unique_product_2021-cte2.unique_product_2020) as difference
from cte1,cte2
where cte1.A=cte2.B;

-- 5  Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select m.product_code, p.product, m.manufacturing_cost
from fact_manufacturing_cost as m
join  dim_product as p
on m.product_code= p.product_code
where manufacturing_cost in(
select max(manufacturing_cost) as manufacturing_cost from fact_manufacturing_cost
union
select min(manufacturing_cost) as manufacturing_cost from fact_manufacturing_cost
)
order by manufacturing_cost desc
;

-- 6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,customer_code. customer average_discount_percentage

select dm.customer_code,dm.customer, round(avg(pre_invoice_discount_pct),4) as average_discount from fact_pre_invoice_deductions as fd
join  dim_customer as dm
on fd.customer_code= dm.customer_code
group by dm.customer_code,dm.market,fd.fiscal_year,dm.customer
having market='India' AND fiscal_year=2021
order by average_discount desc 
limit 5;

-- 7 . Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.The final report contains these columns: Month,Year,Gross sales Amount

select MONTHNAME(fs.date) as Month, YEAR(fs.date) as Year , Sum(fg.gross_price*fs.sold_quantity) as gross_sales_amount from dim_customer as dm
join fact_sales_monthly as fs
on fs.customer_code= dm.customer_code
join fact_gross_price as fg
on fs.product_code= fg.product_code
where dm.customer="Atliq Exclusive"
group by Month,Year
order by year;

-- 8  In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
-- Quarter total_sold_quantity

select 
	case
		when MONTH(date) between 9 and 11 THEN "Q1"
		when MONTH(date)=12 or MONTH(date) between 1 and 2 THEN "Q2"
		when MONTH(date) between 3 and 5 THEN "Q3"
		when MONTH(date) between 6 and 8 THEN "Q4"
	    end as quarter,
		round(sum(sold_quantity )/1000000,2) as total_sold_quantity 
from fact_sales_monthly
where fiscal_year=2020
group by quarter;

-- 9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
-- channel, gross_sales_mln,percentage

WITH cte as (
          Select dm.channel,Sum(fg.gross_price*fs.sold_quantity) as total_sales from dim_customer as dm 
          join fact_sales_monthly as fs
          on dm.customer_code=fs.customer_code
		  join fact_gross_price as fg
		  on fs.product_code= fg.product_code
          where fs.fiscal_year=2021
          group by channel
          )
		 select channel, round(total_sales/1000000,2) as gross_sales_amount_mln,
         round(total_sales/sum(total_sales)over()*100,2) as percentage_contribution from cte
         order by percentage_contribution desc
         limit 1;
         
-- 10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,division, product_code,product,total_sold_quantity,rank_order.

WITH cte as(
select dm.division ,dm.product,dm.product_code,sum(fs.sold_quantity) as total_sold_quantity,
RANK() OVER(partition by dm.division order by sum(fs.sold_quantity)  desc ) as rank_order from dim_product as dm
join fact_sales_monthly as fs
on dm.product_code=fs.product_code
where fs.fiscal_year=2021
group by dm.division ,dm.product,dm.product_code
)
select *from cte
where rank_order in (1,2,3);



