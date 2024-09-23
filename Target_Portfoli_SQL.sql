-- Lets get the time range between orders were placed

select
	min(order_purchase_timestamp) as min_time,
	max(order_purchase_timestamp) as Max_time
from 
	s1.orders
where
	order_id is not null

-- "shows that orders were placed between september 2016 to october 2018"
	
-------------------------------------------------------------------------------------------------------------------------------------
	
--Lets count the cities and states of customers who ordered during given period

select 
	count(distinct a.customer_city) as cities,
	count(distinct a.customer_state) as states
from 
	s1.customer a
inner join 
	s1.orders b on
	a.customer_id = b.customer_id
where
	b.order_id is not null

-- the output is showing that dataset has 27 states and 4119 cities from where orders were placed during that period of time

--------------------------------------------------------------------------------------------------------------------------------------

-- Lets see trend of orders placed over past years

select
	extract( year from order_purchase_timestamp) as Years,
	count(order_id) as No_of_orders
from 
	s1.orders
group by 1
order by 1

-- output is clearly showing that orders were significantly increased over time
-- the growth of orders between 2016 to 2017 is exponantial

--------------------------------------------------------------------------------------------------------------------------------------

-- lets see monthly seasonality in growth of orders


select 
	extract( year from order_purchase_timestamp) as Years,
	extract(Month from order_purchase_timestamp) as Month,
	count(order_id) as No_of_orders
from 
	s1.orders
group by 1,2
order by 1,2

-- ouput is showing that orders were significantly increased in November 2017 due to Black friday Sales
-- Also the growth is seen during January 2017 and January 2018 due to New Year Eve

--------------------------------------------------------------------------------------------------------------------------------------

-- Checking the time of the day orders were placed

select 
	count(*) AS no_of_orders,
	case when extract(hour from order_purchase_timestamp) between 0 and 6 then 'Dawn'
	when  extract( hour from order_purchase_timestamp) between 7 and 12 then 'Morning'
	when extract ( hour from order_purchase_timestamp) between 13 and 18 then 'Afternoon'
	when extract (hour from order_purchase_timestamp) between 19 and 24 then 'Night'
	end as time_of_day
from 
	s1.orders
group by 
	time_of_day
order by 1 desc

-- Data output shows that customers orders were the most in  Afternoon followed by night , Morning and Dawn 
-- Targeted marketing during this time can significantly increase the orders

--------------------------------------------------------------------------------------------------------------------------------------

-- Month on Month no. of orders placed in states

select
	a.customer_state, 
	extract(month from b.order_purchase_timestamp) as months,
	count(*) as no_of_orders
from s1.customer a
inner join 
	s1.orders b on 
	a.customer_id = b.customer_id 
group by 1,2
order by 1,2

-- state SP showing highest no of orders among all the states every month 
-- month on month orders data helps industry to manage the inventory for specific months when orders are in huge numbers 
-- this will aslo helps to understand why certain states are not producing orders even during the high volume months

--------------------------------------------------------------------------------------------------------------------------------------

-- Lets see how all the customers are distributed across all the states

select 
	customer_state,
	count(distinct customer_id) as no_of_customers
from
	s1.customer
group by 1
order by 2 desc

-- output shows that highest no of customers of Target company in Brazil is from State named SP and lowest are from RR
--  this helps to identify opportunities for expansion in states where customers are less.

--------------------------------------------------------------------------------------------------------------------------------------

-- lets see Percent increase in cost from 2017 to 2018 between januray to aug

with initial as(
	select * 
	from
	s1.payments p 
	join 
	s1.orders o on
	p.order_id = o.order_id
	where 
	extract(year from o.order_purchase_timestamp) between 2017 and 2018
	and extract(month from o.order_purchase_timestamp) between 1 and 8 
),
final as(
	select 
	extract(year from order_purchase_timestamp) as years,
	sum(payment_value) as cost
	from 
	initial
	group by 1
	order by 1
)
select 
	* , 
	round(100*(lead(cost, 1) over(order by years) - cost)/cost,2) as percent_increase_yoy
from 
	final

--the output shows us that there has been an increase of approximately 137% in the number of orders from 2017 to 2018
--(Only months from January to August are considered in the code.)

-------------------------------------------------------------------------------------------------------------------------------------

-- Calculating the Total value and average value of orders price in each state

select 
	c.customer_state,
	round(sum(p.payment_value),2) as total_value,
	round(avg(p.payment_value),2) as avg_value
from 
	s1.payments p 
inner join 
	s1.orders o on
	p.order_id = o.order_id
inner join 
	s1.customer c on
	o.customer_id = c.customer_id
group by 1
order by 2 desc

--state SP has the highest total_value.  States with higher and lower average spending  can be studied and 
--necessary interventions can be made to improve the metrics.

-------------------------------------------------------------------------------------------------------------------------------------

--Calculating the Total & Average value of order freight for each state.

select 
	c.customer_state,
	round(sum(o.freight_value),2) as total_freight_value,
	round(avg(o.freight_value),2) as avg_freight_value
from 
	s1.order_items o
inner join
	s1.orders oo on
	o.order_id = oo.order_id
inner join 
	s1.customer c on
	oo.customer_id = c.customer_id
group by 1
order by 2 desc

--he output shows us states with high total freight cost  which means states with high shipping charges.
--Here, the state called SP has the highest total_freightvalue. This can help in improving the logistics and shipping procedures in 
--the states with high total, thereby cutting down  shipping/logistics expenditure and increasing profits. 

-------------------------------------------------------------------------------------------------------------------------------------

--Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. 
--Also, calculate the difference (in days) between the estimated & actual delivery date of an order.

with final as(
	select 
		order_id,order_purchase_timestamp::date AS order_date,
       	order_delivered_customer_date::date AS delivery_date,
       	order_estimated_delivery_date::date AS estimated_date
	from 
	s1.orders
	where
	order_delivered_customer_date is not null 
	and order_estimated_delivery_date is not null
)
select 
	order_id,
	(delivery_date  - order_date) as delivery_time,
	(estimated_date - delivery_date) as diff_estimated_time
from 
	final

-- The following output gives insights into the efficacy of the 
--delivery process, whether it is delivered before the estimated date or not

-------------------------------------------------------------------------------------------------------------------------------------

--Find out the top 5 states with the highest & lowest average freight value. 

(select
	c.customer_state as High1_5_Low6_10,
	round(avg(o.freight_value),2) as Avg_Freight_value
from 
	s1.order_items o
inner join 
	s1.orders oo on 
	o.order_id = oo.order_id
inner join 
	s1.customer c on
	oo.customer_id = c.customer_id
group by 1 
order by 2 desc
limit 5)
	
union all
	
(select
	c.customer_state ,
	round(avg(o.freight_value),2) as avg_freight_value 
from 
	s1.order_items o
inner join 
	s1.orders oo on 
	o.order_id = oo.order_id
inner join 
	s1.customer c on
	oo.customer_id = c.customer_id
group by 1 
order by 2
limit 5)

-- states with high average freight value will have greater shipping costs as compared to states with less average freight value. 
--This data will help the company in analysing expensive shipping partners and help look for ways to reduce supply chain 
--expenditures  so that the profits can be increased. 

-------------------------------------------------------------------------------------------------------------------------------------

-- top selling product categories
	

SELECT 
    pr.product_category,
    SUM(oi.order_item_id) AS total_quantity_sold,
    SUM(oi.price * oi.order_item_id) AS total_revenue
FROM 
    s1.products pr
JOIN 
    s1.order_items oi ON pr.product_id = oi.product_id
GROUP BY 
    pr.product_category
ORDER BY 
    total_revenue DESC;


-------------------------------------------------------------------------------------------------------------------------------------

-- Sellers Performance Analysis


SELECT 
    s.seller_id,
    COUNT(o.order_id) AS total_orders,
    SUM(oi.price * oi.order_item_id) AS total_sales
FROM 
    s1.sellers s
JOIN 
    s1.order_items oi ON s.seller_id = oi.seller_id
JOIN 
    s1.orders o ON oi.order_id = o.order_id
GROUP BY 
    s.seller_id
ORDER BY 
    total_sales DESC
LIMIT 10;

-- The results shows seller id "6560211a19b47992c3666cc44a7e94c0" has highest orders while seller id "7c67e1448b00f6e969d365cea6b010ab"
-- has highest revenue with 1364 total orders

----------------------------------------------------------------------------------------------------------------------------------------
-- Payments Method Popularity
-- Analyze the distribution in payments method in transactions

SELECT 
    p.payment_type,
    COUNT(p.order_id) AS number_of_transactions,
    SUM(p.payment_value) AS total_payment_value
FROM 
    s1.payments p
GROUP BY 
    p.payment_type
ORDER BY 
    total_payment_value DESC;

-- results shows credit card is top priority for payments followed by UPI

-------------------------------------------------------------------------------------------------------------------------------------

-- top 5 highest and lowest spending customers

(SELECT 
    c.customer_id,
    COUNT(o.order_id) AS total_orders,
    SUM(p.payment_value) AS total_spent
FROM 
    s1.customer c
JOIN 
    s1.orders o ON c.customer_id = o.customer_id
JOIN 
    s1.payments p ON o.order_id = p.order_id
GROUP BY 
    c.customer_id
ORDER BY 
    total_spent DESC limit 5)

Union All
	
(SELECT 
    c.customer_id,
    COUNT(o.order_id) AS total_orders,
    SUM(p.payment_value) AS total_spent
FROM 
    s1.customer c
JOIN 
    s1.orders o ON c.customer_id = o.customer_id
JOIN 
    s1.payments p ON o.order_id = p.order_id
GROUP BY 
    c.customer_id
having 
	sum(p.payment_value) <> 0
ORDER BY 
    total_spent asc limit 5)

-------------------------------------------------------------------------------------------------------------------------------------


