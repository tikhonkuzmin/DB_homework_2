create table hw2_customer (
	 customer_id int primary key	
	,first_name	varchar
	,last_name varchar
	,gender varchar
	,DOB date
	,job_title varchar
	,job_industry_category varchar	
	,wealth_segment varchar	
	,deceased_indicator varchar
	,owns_car varchar
	,address varchar	
	,postcode int
	,state varchar
	,country varchar
	,property_valuation varchar
)

create table hw2_product (
	product_id int
	,brand varchar
	,product_line varchar
	,product_class varchar
	,product_size varchar
	,list_price float
	,standard_cost float
)

create table hw2_orders (
	order_id int primary key
	,customer_id int
	,order_date date
	,online_order bool
	,order_status varchar
)

create table hw2_order_items (
	order_item_id int
	,order_id int
	,product_id int
	,quantity int
	,item_list_price_at_sale float
	,item_standard_cost_at_sale float
);

--1.	Вывести все уникальные бренды, у которых есть хотя бы один 
--		продукт со стандартной стоимостью выше 1500 долларов, и 
--		суммарными продажами не менее 1000 единиц.

select p.brand
from public.hw2_product p
join public.hw2_order_items oi on p.product_id = oi.product_id 
where p.standard_cost > 1500
group by p.brand 
having sum (oi.quantity) >= 1000

--2. 	Для каждого дня в диапазоне с 2017-04-01 по 2017-04-09 
--	включительно вывести количество подтвержденных онлайн-заказов 
--	и количество уникальных клиентов, совершивших эти заказы.

select order_date
	,count (order_id) as order_count
	,count (distinct customer_id) as customer_count
from public.hw2_orders
where order_date between '2017-04-01' and '2017-04-09'
group by (order_date)
order by (order_date)

--3. 	Вывести профессии клиентов: из сферы IT, чья профессия начинается с Senior; 
--		из сферы Financial Services, чья профессия начинается с Lead.
--		Для обеих групп учитывать только клиентов старше 35 лет. Объединить выборки с помощью UNION ALL.

select job_title
from public.hw2_customer
where job_industry_category = 'IT'
	and job_title like 'Senior%'
	and extract (year from age('2017-01-01'::date, dob)) > 35
union all
select job_title
from public.hw2_customer
where job_industry_category = 'Financial Services'
	and job_title like 'Lead%'
	and extract(year from age('2017-01-01'::date, dob)) > 35
--нет ни одного из финансов
	
--4.	Вывести бренды, которые были куплены клиентами из сферы Financial Services, 
--		но не были куплены клиентами из сферы IT.
	
select distinct p.brand
from public.hw2_order_items oi
join public.hw2_orders o on oi.order_id = o.order_id 
join public.hw2_product p on oi.product_id  = p.product_id
join public.hw2_customer c on o.customer_id = c.customer_id
where c.job_industry_category = 'Financial Services'
	and p.brand not in (
		select distinct p2.brand
		from public.hw2_order_items oi2
		join public.hw2_orders o2 on oi2.order_id = o2.order_id 
		join public.hw2_product p2 on oi2.product_id  = p2.product_id
		join public.hw2_customer c2 on o2.customer_id = c2.customer_id
		where c2.job_industry_category = 'IT'
	)

--5. 	Вывести 10 клиентов (ID, имя, фамилия), которые совершили наибольшее 
--		количество онлайн-заказов (в штуках) брендов Giant Bicycles, Norco Bicycles, 
-- 		Trek Bicycles, при условии, что они активны и имеют оценку имущества 
--		(property_valuation) выше среднего среди клиентов из того же штата.

select c.customer_id, c.first_name, c.last_name, state, count(o.order_id) as online_order_count
from public.hw2_customer c
join public.hw2_orders o on c.customer_id = o.customer_id  
join public.hw2_order_items oi on o.order_id = oi.order_id
join public.hw2_product p on oi.product_id  = p.product_id
where
	c.deceased_indicator = 'N'
	and o.online_order = true
	and p.brand in ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
	and c.property_valuation > (
		select avg (c2.property_valuation)
		from public.hw2_customer c2
		where c2.state = c.state
		)
group by c.customer_id, c.first_name, c.last_name 
order by online_order_count desc
limit 10

--6. 	Вывести всех клиентов (ID, имя, фамилия), у которых нет подтвержденных онлайн-заказов 
--		за последний год, но при этом они владеют автомобилем и их сегмент благосостояния 
--		не Mass Customer.

select c.customer_id, c.first_name, c.last_name 
from public.hw2_customer c
join public.hw2_orders o on c.customer_id = o.customer_id 
where 
	o.online_order in (true, null)
	and o.order_status = 'Cancelled'
	or o.online_order = null
	and c.owns_car = 'Yes'
	and c.wealth_segment not in ('Mass Customer')

--7.	Вывести всех клиентов из сферы 'IT' (ID, имя, фамилия), которые купили 2 из 5 продуктов 
--		с самой высокой list_price в продуктовой линейке Road.

with top5road as (
	select product_id
	from public.hw2_product
	where product_line = 'Road'
	order by list_price desc
	limit 5
),

buyerlist as (
	select c.customer_id, c.first_name, c.last_name, oi.product_id 
	from public.hw2_customer c
	join public.hw2_orders o on c.customer_id = o.customer_id
	join public.hw2_order_items oi on o.order_id = oi.order_id
	where c.job_industry_category = 'IT'
		and oi.product_id in (select product_id from top5road)
)

select customer_id, first_name, last_name
from (
	select customer_id, first_name, last_name, count (distinct product_id) as 
	unique_product_count
	from buyerlist
	group by customer_id, first_name, last_name 
) sub
where unique_product_count >=2;

--8. 	Вывести клиентов (ID, имя, фамилия, сфера деятельности) из сфер IT или Health, 
--		которые совершили не менее 3 подтвержденных заказов в период 2017-01-01 по 2017-03-01, 
--		и при этом их общий доход??? от этих заказов превышает 10 000 долларов. 
--		Разделить вывод на две группы (IT и Health) с помощью UNION.

select c.customer_id, c.first_name, c.last_name, c.job_industry_category
from public.hw2_customer c
join (
	select o.customer_id, count (distinct o.order_id) as approved_orders,
		sum (oi.quantity * oi.item_list_price_at_sale) as total_revenue
	from public.hw2_orders o
	join public.hw2_order_items oi on o.order_id = oi.order_id 
	where o.order_status = 'Approved'
		and o.order_date >= '2017-01-01'
		and o.order_date <= '2017-03-01'
	group by o.customer_id 
)
agg on c.customer_id = agg.customer_id 
where c.job_industry_category = 'IT'
	and agg.approved_orders >= 3
	and agg.total_revenue > 10000
	
union

select c.customer_id, c.first_name, c.last_name, c.job_industry_category
from public.hw2_customer c
join (
	select o.customer_id, count (distinct o.order_id) as approved_orders,
		sum (oi.quantity * oi.item_list_price_at_sale) as total_revenue
	from public.hw2_orders o
	join public.hw2_order_items oi on o.order_id = oi.order_id 
	where o.order_status = 'Approved'
		and o.order_date >= '2017-01-01'
		and o.order_date <= '2017-03-01'
	group by o.customer_id 
)
agg on c.customer_id = agg.customer_id 
where c.job_industry_category = 'Health'
	and agg.approved_orders >= 3
	and agg.total_revenue > 10000


