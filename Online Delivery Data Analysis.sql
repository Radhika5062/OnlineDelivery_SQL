-- Creating driver table
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 
-- Inserting into driver table
INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');

-- Creating Ingredients table
drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 
--Inserting into Ingredients table
INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

-- Creating Rolls table
drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 
-- Inserting into Rolls table
INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

-- Creating rolls_recipes table
drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 
-- Inserting data into rolls_recipes table
INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

-- Creating driver_order table
drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time timestamp,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
-- Inserting into driver_order table
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);

-- Creating customer_orders table
drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date timestamp);
-- Inserting into customer_orders table
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

-- Viewing all tables
select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

--1. How many rolls were ordered?
select count(order_id) as total_rolls_ordered
from customer_orders

--2. How many unique customer orders were made
select count(distinct customer_id) as total_number_of_customers
from customer_orders

--3. How many successful orders were delivered by each drivers
select driver_id, count(distinct order_id) as total_successful_order_delivered_count
from driver_order
where cancellation not in ('Cancellation', 'Customer Cancellation')
group by driver_id

--4. How many rolls were delivered for each type
with cleanup as
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'cancelled' else 'delivered' end as finalisedStatus
		from driver_order
	)
select co.roll_id, count(finalisedStatus) as total_number_of_rolls_delivered
from customer_orders co
join cleanup cl
on co.order_id = cl.order_id
where cl.finalisedStatus = 'delivered'
group by co.roll_id
order by co.roll_id

--5. How many Veg and Non Veg rolls were ordered by each customer
-- This data will provide us information about the roll preference for each of the customers. 
-- This will help in deciding marketting strategies, analysing pricing, understanding 
-- which roll is popular and what kind of food preference do people have etc. 
select co.customer_id, r.roll_name, count(r.roll_name) as total_number_of_rolls_ordered
from customer_orders co
join rolls r
on co.roll_id = r.roll_id
group by co.customer_id, r.roll_name
order by r.roll_name

--6. What was the maximum number of rolls delivered in a single order?
with orderStatus as
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'Cancelled' else 'Delivered' end as Status
		from driver_order
	),
totalRollCount as
	(
		select co.order_id, count(roll_id) as RollCount
		from customer_orders co
		join orderStatus os
		on co.order_id = os.order_id
		where os.Status = 'Delivered'
		group by co.order_id
	)
select max(RollCount) as max_number_of_rolls_in_one_order
from totalRollCount

--7. For each customer, how many delivered ROLLS had at least 1 change and how many had no changes?
with orderStatus as 
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'Cancelled' else 'Delivered' end as Status
		from driver_order 
	),
changeStatus as 
	(
		select order_id,customer_id, roll_id, not_include_items, extra_items_included, 
		case when not_include_items is null 
				or not_include_items = '' 
				then 'No' 
		else 'Yes' end as EditMade1,
		case when extra_items_included is null or extra_items_included = '' or extra_items_included ='NaN' then 'No' else 'Yes' end as EditMade2
		from customer_orders
	),
FinalChangeStatus as
	(
		select cs.order_id, cs.customer_id, cs.roll_id,
		case when EditMade1 = 'No' and EditMade2 = 'No' then 'No change' else 'Change' end as FinalStatus
		from orderStatus os
		join changeStatus cs
		on os.order_id = cs.order_id
		where os.Status = 'Delivered'
	)
select customer_id, finalStatus, count(*) as total_number_of_rolls
from FinalChangeStatus
group by customer_id, finalStatus
order by finalStatus

--8. For each customer, which delivered ORDERS had at least 1 change and which ones had no changes?
-- This helps to understand what changes have been requested by customers to understand if 
-- there are any changes required in the recipe to better suit customers. 
with getChangeData as
	(
		select *, 
		case when not_include_items is null
			or not_include_items = '' 
			then 0 else 1 end as EditMade1,
		case when extra_items_included is null
			or extra_items_included = '' 
			or extra_items_included = 'NaN'
			then 0 else 1 end as EditMade2
		from customer_orders
	),
	getUnconsolidatedData as
	(
		select *, 
		case when EditMade1 = 0 and EditMade2 = 0 then 'No Change' else 'Change' end as ChangeData
		from getChangeData
	),
	getConsolidatedData as
	(
		select g1.order_id as order_num, g1.roll_id, g2.order_id, g2.roll_id, g1.changedata,g2.changedata, 'Change' as Status
		from getUnconsolidatedData g1
		join getUnconsolidatedData g2
		on g1.order_id = g2.order_id
		and g1.changedata != g2.changedata
	),
	cte as 
	(
		select order_id, ChangeData
		from getUnconsolidatedData
		where order_id not in (select order_num from getConsolidatedData)
		union
		select order_num, Status
		from getConsolidatedData
		group by order_num, Status
	),
	getDeliveredData as
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'Cancelled' else 'Delivered' end as Status
		from driver_order 
	)
select c.order_id, c.changeData as change_status
from cte c
join getDeliveredData g
on c.order_id = g.order_id
where g.Status = 'Delivered'
order by c.order_id



--9. How many rolls were delivered that had both exclusions and extras
with orderStatus as 
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'Cancelled' else 'Delivered' end as Status
		from driver_order 
	),
changeStatus as 
	(
		select order_id,customer_id, roll_id, not_include_items, extra_items_included, 
		case when not_include_items is null 
				or not_include_items = '' 
				then 'No' 
		else 'Yes' end as EditMade1,
		case when extra_items_included is null or extra_items_included = '' or extra_items_included ='NaN' then 'No' else 'Yes' end as EditMade2
		from customer_orders
	),
	getDeliveredData as
	(
		select order_id, 
		case when cancellation in ('Cancellation', 'Customer Cancellation') then 'Cancelled' else 'Delivered' end as Status
		from driver_order 
	)
select count(*) as total_number_of_rolls_with_both_exclusion_and_extra
from changeStatus c
join getDeliveredData g
on c.order_id = g.order_id
where EditMade1 = 'Yes' and EditMade2 = 'Yes'
and g.Status = 'Delivered'

--10. What were the total number of rolls ordered for each hour of the day?
-- This data helps business guage peak time when sales happen as well as the time of day when there are less sales. 
-- This helps to understand what factors are driving sales and what needs to be done during the less busy period to drive sales - for examples 
-- running some promotional offers during less busy hours.  
with buckets as 
	(
		select order_id, concat(cast(date_part('hour', order_date) as varchar(10)), ' - ', cast(date_part('hour', order_date) + 1 as varchar(10))) as hourrange
		from customer_orders
	)
select hourrange as hour_of_day, count(hourrange) as total_number_of_rolls_ordered
from buckets
group by hourrange
order by hourrange 

--11. What are the total number of orders each day of week?
-- There could be multiple entries of same order as each line contains informatiom about one roll present in order. Hence in this case we cannot
--simply count dow and will have to use distinct order_id to get the correct value. 
with daybuckets as
	(
		select order_id, order_date,
		to_char(order_date, 'Day') as dow
		from customer_orders
	)
select dow as day_of_week, count(distinct order_id) as total_number_of_orders
from daybuckets
group by dow
order by dow

--12. What was the average time in minutes it took for each driver to arrive at the Fasoos HQ to pickup the order?
with cleanOrders as 
	(
		select order_id, max(order_date) as odate
		from customer_orders
		group by order_id
	),
	cleanDrivers as
	(
		select order_id, driver_id, pickup_time
		from driver_order
		where pickup_time is not null
	),
	difference as
	(
		select o.order_id, driver_id, odate, pickup_time, extract(minutes from pickup_time - odate) as diff, 
		pickup_time - odate
		from cleanOrders o
		join cleanDrivers d
		on o.order_id = d.order_id
	)
select driver_id, concat(round(sum(diff)/count(order_id),0), ' minutes') as avg_time_to_arrive_for_pickup
from difference
group by driver_id
order by driver_id

--13. Is there any relationship between the number of rolls and how long the order takes to prepare
--We can use the output of this data to plot chart using excel, Tableau or Power BI to understand the relationship better.
with cleanOrders as 
	(
		select order_id, max(order_date) as odate
		from customer_orders
		group by order_id
	),
	cleanDrivers as
	(
		select order_id, driver_id, pickup_time
		from driver_order
		where pickup_time is not null
	),
	difference as
	(
		select o.order_id, driver_id, odate, pickup_time, extract(minutes from pickup_time - odate) as diff, 
		pickup_time - odate
		from cleanOrders o
		join cleanDrivers d
		on o.order_id = d.order_id
	)
select o.order_id, count(o.roll_id) as total_rolls_count, concat(round(sum(diff)/count(roll_id),0), ' minutes') as time_to_prepare
from customer_orders o
join cleanDrivers d
on o.order_id = d.order_id
join difference di
on di.order_id = o.order_id
group by o.order_id
order by o.order_id

--14. What was the average distance travelled for each customer. 
with cleanData as
	(
		select d.order_id, o.customer_id, d.driver_id, cast(replace(d.distance,'km','') as numeric) as dist,
		row_number() over(partition by d.order_id) as rn
		from customer_orders o
		join driver_order d
		on o.order_id = d.order_id
		where d.distance is not null
	)
select customer_id, concat(round(sum(dist)/count(order_id),0), ' km') as avg_distance_travelled_per_customer
from cleanData
where rn = 1
group by customer_id

--15. What is the difference between the longest and the shortest delivery times for all orders?
-- Duration field defines the time it took to delivery the order.
with durationData as
	(
		select duration, cast(replace(replace(replace(duration, 'minutes', ''),'mins',''),' minute','') as int) as d
		from driver_order
		where duration is not null
	)
select concat(max(d) - min(d), ' minutes') as time_difference
from durationData

--16. What was the average speed for each driver for each delivery and do you notice any trend for these values?
--speed in km/hr
with cleanDriver as
	(
		select order_id, driver_id, cast(replace(replace(replace(duration, 'minutes', ''),'mins',''),' minute','') as int) as dur,
		cast(replace(distance,'km','') as numeric) as dist
		from driver_order
		where duration is not null
	)
select order_id, driver_id, concat(round((dist/dur) * 60,0),'km/hr') as speed 
from cleanDriver

--speed in km/min
with cleanDriver as
	(
		select order_id, driver_id, cast(replace(replace(replace(duration, 'minutes', ''),'mins',''),' minute','') as int) as dur,
		cast(replace(distance,'km','') as numeric) as dist
		from driver_order
		where duration is not null
	)
select order_id, driver_id, concat(round((dist/dur),2),'km/min') as speed 
from cleanDriver


--17. What is the successful delivery percentage for each driver?
with cte as
	(
		select driver_id, sum(status) as success, count(driver_id) as tot
		from
			(
				select order_id, driver_id, case when cancellation in ('Cancellation' , 'Customer Cancellation') then 0 else 1 end as status
				from driver_order
			) a
		group by driver_id
	)
select driver_id, concat(round(success * 1.0/tot,2) * 100, '%') as successful_delivery_percentage
from cte
order by driver_id




	
	
	
	
	
	
	
	
	

