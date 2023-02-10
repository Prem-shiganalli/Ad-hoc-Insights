/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
usiness in the APAC region */

select distinct(market),region,customer
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,*/

with Unique_product_2020 as
(SELECT  count(distinct product_code) as Unique_products_2020 FROM gdb023.fact_gross_price where fiscal_year = 2020),
unique_product_2021 as
(SELECT  count(distinct product_code) as Unique_products_2021 FROM gdb023.fact_gross_price where fiscal_year = 2021)
select a.unique_products_2020, 
	   b.unique_products_2021,
       round((((b.unique_products_2021-a.unique_products_2020)/a.unique_products_2020)*100),2) as percent_chg
from unique_product_2020 a
join unique_product_2021 b;

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts.*/

select count(distinct product_code),segment from dim_product group by segment order by count(distinct product_code) desc;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? */

with cte_20 as 
(select p.segment,count(distinct p.product_code) as product_count_2020
from dim_product p
inner join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2020
group by p.segment
order by product_count_2020 desc),
  cte_21 as 
(select p.segment,count(distinct p.product_code) as product_count_2021
from dim_product p
inner join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.segment
order by product_count_2021 desc)
select cte_20.segment
product_count_2020,product_count_2021,
product_count_2021-product_count_2020 as difference
from cte_20
inner join cte_21 on cte_20.segment = cte_21.segment
order by 'difference' desc;

/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,*/

select m.manufacturing_cost,m.product_code,p.product
from fact_manufacturing_cost m
inner join dim_product p on m.product_code = p.product_code
where m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
union
select m.manufacturing_cost,m.product_code,p.product
from fact_manufacturing_cost m
inner join dim_product p on m.product_code = p.product_code
where m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market.*/

select c.customer_code, c.customer, p.pre_invoice_discount_pct
from dim_customer c
inner join fact_pre_invoice_deductions  p
on c.customer_code = p.customer_code
where p.pre_invoice_discount_pct > (SELECT avg(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions) and c.market = 'india' and p.fiscal_year = 2021
order by p.pre_invoice_discount_pct desc
limit 5; 

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.*/

select month(s.date) as month, year(s.date) as year,sum(round(s.sold_quantity * g.gross_price)) as gross_sales_amt
from fact_sales_monthly s 
inner join fact_gross_price g on s.product_code = g.product_code
inner join dim_customer c on s.customer_code = c.customer_code
where c.customer = "Atliq Exclusive"
group by month, year
order by year;

/*8. In which quarter of 2020, got the maximum total_sold_quantity?*/

select case 
   when month(date) in (9,10,11) then "Qtr 1"
    when month(date) in (12,1,2) then "Qtr 2"
     when month(date) in (3,4,5) then "Qtr 3"
      when month(date) in (6,7,8) then "Qtr 4"
      end as Qtr,
      sum(sold_quantity) as total_sales_quantity
      from fact_sales_monthly 
      where fiscal_year = 2020
      group by Qtr
      order by total_sales_quantity desc;
      
/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution*/

with gross_sales_cte as
(select c.channel, round(sum(s.sold_quantity * g.gross_price)/1000000,2) as gross_sales_mlm
from fact_sales_monthly s
inner join fact_gross_price g on s.product_code = g.product_code
inner join dim_customer c on s.customer_code = c.customer_code
where s.fiscal_year = 2021
group by c.channel
order by gross_sales_mlm desc)
select *, gross_sales_mlm*100/sum(gross_sales_mlm) over () as percent
from gross_sales_cte;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?*/

with division_sales_cte as 
(select p.division, s.product_code,p.product, sum(s.sold_quantity) as 'total_sold_qty', 
row_number() over (partition by p.division order by sum(s.sold_quantity) desc) as rank_order
from fact_sales_monthly s 
inner join dim_product p
on s.product_code = p.product_code
where s.fiscal_year = 2021
group by p.division, s.product_code, p.product)
select division, product_code, product, total_sold_qty, rank_order
from division_sales_cte
where rank_order <= 3;