create database monday_coffee;

use monday_coffee;

select * from city;

select * from customers;

select * from products;

select * from sales;

		-- Q1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
        
select city_name, population * 0.25 coffee_consumers , city_rank 			--  GIVEN THAT 25% CONSUME COFFEE	
from city
order by population desc; 

		--  What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
	
select count(customer_id) as total_customers, Sum(total) as total_revenue
from sales 
where year(sale_date) =  2023
and quarter(sale_date) = 4 ;

			-- How many units of each coffee product have been sold?
            
select p.product_name, count(s.sale_id) total_units_sold from products p 
left join sales s 
on p.product_id = s.product_id
group by product_name;

			--  What is the average sales amount per customer in each city?
            
select
cty.city_name,
avg(customer_total.total_per_customer) as avg_sales_per_customer
from (
select 
customers.city_id,
s.customer_id,
sum(s.total) as total_per_customer
from sales s
join customers on  s.customer_id = customers.customer_id
group by customers.city_id, s.customer_id
) as customer_total
join city cty on customer_total.city_id = cty.city_id
group by cty.city_name
order by avg_sales_per_customer desc;

		  --  Provide a list of cities along with their populations and estimated coffee consumers.
          
select c.city_name,c.population,
count(distinct cu.customer_id) as  customers_in_city,
round(c.population * 0.20) as est_20pct_customers,
round(c.population * 0.25) as est_25pct_customers,
round(c.population * 0.30) as est_30pct_customers
from city c
left join customers cu
on c.city_id = cu.city_id
group by c.city_id,
c.city_name,c.population
order by c.population desc;

			--  What are the top 3 selling products in each city based on sales volume?

with city_product_sales as (
select 
cty.city_name,
p.product_name,
sum(s.total) as total_sales
from sales s
join products p on s.product_id = p.product_id
join customers cu on s.customer_id = cu.customer_id
join city cty on cu.city_id = cty.city_id
group by cty.city_name, p.product_name
),
ranked_sales as (
select 
city_name,
product_name,
total_sales,
rank() over (partition by city_name order by total_sales desc) as rnk 
from city_product_sales
)
select 
city_name,
product_name,
total_sales,
rnk as rank_in_city
from ranked_sales
where rnk <= 3
order by city_name, rnk;

		-- How many unique customers are there in each city who have purchased coffee products?
        
select cty.city_name,
count(distinct cu.customer_id) as unique_customers
from sales s
join products p on s.product_id = p.product_id
join customers cu on s.customer_id = cu.customer_id
join city cty on cu. city_id = cty.city_id
where p.product_name like '%coffee%'
group by cty.city_name
order by unique_customers desc;

		--  Find each city and their average sale per customer and avg rent per customer
        
with customer_sales as (
select
cu.city_id,
s.customer_id,
sum(s.total) as total_sales_per_customer
from sales s
join customers cu on s.customer_id = cu.customer_id
group by cu.city_id, s.customer_id
)
select 
cty.city_name,
round(avg(cs.total_sales_per_customer), 2) as avg_sales_per_customer,
round(cty.estimated_rent / count(distinct cs.customer_id), 2) as avg_rent_per_customer
from customer_sales cs
join city cty on cs.city_id = cty.city_id
group by cty.city_name, cty.estimated_rent
order by avg_sales_per_customer desc;

		  --  Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

with monthly_sales as (
select
date_format(s.sale_date, '%Y-%m') AS month,
sum(s.total) AS total_sales
from sales s
group by date_format(s.sale_date, '%Y-%m')
),
growth_calc as (
select
month,
total_sales,
lag(total_sales) over (order by month) as prev_month_sales
from monthly_sales
)
select
month,
total_sales,
prev_month_sales,
round(
case 
when prev_month_sales = 0 OR prev_month_sales is null then null
else ((total_sales - prev_month_sales) / prev_month_sales) * 100
end , 2
) as sales_growth_percent
from growth_calc
order by month;

			   --  Identify top 3 city based on highest sales, return city name, 
               -- total sale, total rent, total customers, estimated coffee consumer

select
cty.city_name,
sum(s.total) as total_sales,
cty.estimated_rent as total_rent,
count(distinct cu.customer_id) as total_customers,
round(cty.population * 0.25) as estimated_coffee_consumers
from sales s
join customers cu on s.customer_id = cu.customer_id
join city cty on cu.city_id = cty.city_id
group by cty.city_id, cty.city_name, cty.estimated_rent, cty.population
order by total_sales desc
limit 3;



