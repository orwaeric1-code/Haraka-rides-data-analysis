</> SQL

-- ===========================================================================================
-- HARAKA RIDES DATA ANALYSIS
-- 5. ANALYSIS
-- Purpose: Answer business questions using the clean database
-- ===========================================================================================

-- =========================================================================================== 
-- PART 1 - Booking Analysis
-- B1: Which 5 drivers have completed the most trips?
-- ===========================================================================================
select
	d.driver_id,
	d.driver_name,
	count(t.trip_id) as completed_trips
from booking.drivers d
join booking.trips t
	on d.driver_id = t.driver_id 
where t.status = 'COMPLETED'
group by 
	d.driver_id,
	d.driver_name 
order by completed_trips desc 
limit 5;

-- ==========================================================================================
-- B2: Customers who have never completed a trip?
-- ==========================================================================================
select 
	c.customer_id,
	c.customer_name,
	c.customer_phone
from booking.customers c
left join booking.trips t
	on c.customer_id = t.customer_id 
	and t.status = 'COMPLETED'
where t.trip_id is null;

-- =========================================================================================
-- B3: Total Revenue by payment method
-- =========================================================================================
select 
	payment_method,
	sum(fare_amount) as total_revenue
from booking.trips 
where status = 'COMPLETED'
group by payment_method 
order by total_revenue desc;

-- =========================================================================================
-- PART 2: Fleet analysis
-- F1: Rank vehicles by total fuel cost
-- =========================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	sum(f.fuel_cost) as total_fuel_cost
from fleet.vehicles v
join fleet.fuel_logs f
	on v.vehicle_id = f.vehicle_id 
group by 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model
order by total_fuel_cost desc;

-- =========================================================================================
-- F2: Vehicles with more than 3 maintenance events
-- =========================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	count(m.maintenance_log_id) as maintenance_events,
	sum(m.maintenance_cost) as total_maintenance_spend
from fleet.vehicles v 
join fleet.maintenance_logs m 
	on v.vehicle_id = m.vehicle_id 
group by 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model 
having count(m.maintenance_log_id) > 3
order by total_maintenance_spend desc;

-- ========================================================================================
-- F3: Vehicles that never had a fuel log
-- ========================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model 
from fleet.vehicles v
left join fleet.fuel_logs f
	on v.vehicle_id = f.vehicle_id 
where f.fuel_log_id is null 
order by v.plate_number; 

-- ========================================================================================
-- Cross-Schema Analysis
-- X1: Completed trips with vehicle details
-- ========================================================================================
select 
	t.trip_id,
	t.trip_date,
	t.pickup_area,
	t.dropoff_area,
	v.plate_number,
	v.make,
	v.model 
from booking.trips t 
join fleet.vehicles v 
	on t.vehicle_id = v.vehicle_id 
where t.status = 'COMPLETED'
order by t.trip_date;

-- ========================================================================================
-- X2: Total revenue per vehicle, including vehicles with zero revenue
-- ========================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	coalesce(sum(
		case 
			when t.status = 'COMPLETED'
			then t.fare_amount
			else 0
		end
		), 0) as total_revenue
from fleet.vehicles v 
left join booking.trips t
	on v.vehicle_id = t.vehicle_id 
group by 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model 
order by total_revenue desc;

-- =======================================================================================
-- X3: Vehicles under repair that still have trips
-- =======================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	v.vehicle_status,
	count(t.trip_id) as trip_count
from fleet.vehicles v 
join booking.trips t 
	on v.vehicle_id = t.vehicle_id 
where upper(trim(v.vehicle_status)) = 'UNDER REPAIR'
group by 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	v.vehicle_status 
order by trip_count desc;

-- ======================================================================================
-- SUBQUERIES
-- S1: Customers riding further than average
-- ======================================================================================
select 
	t.trip_id,
	c.customer_name,
	t.distance_km
from booking.trips t
join booking.customers c 
	on t.customer_id = c.customer_id 
where t.distance_km > (  
	select AVG(distance_km) 
	from booking.trips 
	where distance_km is not null )
order by t.distance_km desc;

-- ======================================================================================
-- S2: Vehicles spending more on fuel than the average vehicle
-- ======================================================================================
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	sum(f.fuel_cost) as total_fuel_cost
from fleet.vehicles v
join fleet.fuel_logs f 
	on v.vehicle_id = f.vehicle_id 
group by 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model
having sum(f.fuel_cost) > ( 
	select avg(vehicle_fuel_total)
	from ( 
		select 
			vehicle_id,
			sum(fuel_cost) as vehicle_fuel_total 
		from fleet.fuel_logs 
		group by vehicle_id 
	) as fuel_totals 
)
order by total_fuel_cost desc;

-- ======================================================================================
-- S3: Completed trips with fares above the average for their payment method
-- ======================================================================================
select 
	t.trip_id,
	t.customer_id,
	t.payment_method,
	t.fare_amount,
	round(avg(t2.fare_amount), 2) as avg_fare_payment_method,
	round(t.fare_amount - avg(t2.fare_amount), 2) as fare_difference
from booking.trips t
join booking.trips t2
	on t.payment_method = t2.payment_method 
	and t2.status = 'COMPLETED'
where t.status = 'COMPLETED'
group by 
	t.trip_id,
	t.customer_id,
	t.payment_method,
	t.fare_amount
order by fare_difference desc;

-- let's try with a correlated subquery

select 
	t.trip_id,
	t.payment_method,
	t.fare_amount
from booking.trips t 
where t.status = 'COMPLETED'
	and t.fare_amount > ( 
		select avg(t2.fare_amount)
		from booking.trips t2  
		where t2.status = 'COMPLETED' 
		and t2.payment_method = t.payment_method 
	)
order by t.payment_method, t.fare_amount desc;

-- =======================================================================================
-- Capstone: Vehicle Profitability Analysis
-- =======================================================================================
with revenue as ( 
	select 
		vehicle_id,
		sum(fare_amount) as total_revenue 
	from booking.trips 
	where status = 'COMPLETED'
	group by vehicle_id 
),
fuel as ( 
	select 
		vehicle_id, 
		sum(fuel_cost) as total_fuel
	from fleet.fuel_logs 
	group by vehicle_id 
), 
maintenance as (   
	select 
		vehicle_id,
		sum(maintenance_cost) as total_maintenance 
	from fleet.maintenance_logs 
	group by vehicle_id 
)
select 
	v.vehicle_id,
	v.plate_number,
	v.make,
	v.model,
	coalesce(r.total_revenue, 0) as total_revenue,
	coalesce(f.total_fuel, 0) as total_fuel,
	coalesce(m.total_maintenance, 0) as total_maintenance,
	coalesce(r.total_revenue, 0)
		- coalesce(f.total_fuel, 0)
		- coalesce(m.total_maintenance, 0) as net_profit,
	rank() over (
		order by 
			coalesce(r.total_revenue, 0)
			- coalesce(f.total_fuel, 0)
			- coalesce(m.total_maintenance, 0) desc  
	) as profit_rank  
from fleet.vehicles v  
left join revenue r on v.vehicle_id = r.vehicle_id  
left join fuel f on v.vehicle_id = f.vehicle_id
left join maintenance m on v.vehicle_id = m.vehicle_id  
order by net_profit desc;

-- =============================================================================================
