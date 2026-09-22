</> SQL

-- ============================================================================================
-- HARAKA RIDES PROJECT
-- 04 - DATA LOADING
-- Purpose: Migrate cleaned staging data into analytical tables
-- ============================================================================================

-- ============================================================================================
-- 1. LOAD VEHICLE
-- ============================================================================================
insert into fleet.vehicles(plate_number, make, model, vehicle_year, vehicle_type, vehicle_status)

select distinct
	upper(regexp_replace(trim(vehicle_plate), '[^A-Za-z0-9]', '', 'g')) as plate_number,
	upper(trim(vehicle_make)) as make,
	upper(trim(vehicle_model)) as model,
	nullif(trim(vehicle_year), '')::INT as vehicle_year,
	upper(trim(vehicle_type)) as vehicle_type,
	upper(trim(vehicle_status)) as vehicle_status
from staging.fleet_staging
where nullif(trim(vehicle_plate), '') is not null;

-- =============================================================================================
-- 2. LOAD CUSTOMERS
-- =============================================================================================
insert into booking.customers(customer_name, customer_phone)
	
select distinct  
		initcap(trim(customer_name)),
		case 
			when customer_phone like '+254%'
			then '0' || substring(regexp_replace(customer_phone, '[^0-9]', '', 'g') from 4)
			else regexp_replace(customer_phone, '[^0-9]', '', 'g') 
		end null 
	from staging.trip_staging
	where nullif(trim(customer_name), '') is not null;

-- =============================================================================================
-- 3. LOAD DRIVERS
-- =============================================================================================
insert into booking.drivers(driver_name, driver_phone)  
	
select 
		initcap(trim(driver_name)) as driver_name,
		max(
		 case 
			when trim(driver_phone) like '+254%'
			then '0' || substring(regexp_replace(driver_phone, '[^0-9]', '', 'g') from 4)
			else nullif(regexp_replace(driver_phone, '[^0-9]', '', 'g'), '')
		end) as driver_phone
	from staging.trip_staging
	where nullif(trim(driver_name), '') is not null
	group by initcap(trim(driver_name));

-- Grouping by the standardized driver name prevents duplicate driver records.

-- =============================================================================================
-- 4. LOAD FUEL LOGS
-- =============================================================================================
insert into fleet.fuel_logs(vehicle_id, event_date, liters, fuel_cost, odometer_reading, station_name)

select v.vehicle_id,
	case 
		when trim(f.event_date) ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(trim(f.event_date), 'YYYY-MM-DD')
	    when trim(f.event_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$' then to_date(trim(f.event_date), 'DD/MM/YYYY')
		when trim(f.event_date) ~ '^\d{1,2}/\d{1,2}/\d{2}$' then to_date(trim(f.event_date), 'DD/MM/YY')
		when trim(f.event_date) ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(trim(f.event_date), 'MM-DD-YYYY')
		else null
	end,
	
	nullif(trim(f.liters), '')::numeric,
	
	nullif(regexp_replace(trim(f.fuel_cost), '[^0-9]', '', 'g'), '')::numeric,
	
	nullif(trim(f.odometer_reading), '')::numeric,
	
	nullif(trim(f.station_name), '')
	
from fleet_staging f
join fleet.vehicles v
on v.plate_number = upper(regexp_replace(trim(f.vehicle_plate), '[^A-Za-z0-9]', '', 'g'))
where lower(trim(f.event_type)) = 'fuel';

-- =======================================================================================================
-- 5. LOAD MAINTENANCE LOGS
-- =======================================================================================================
insert into fleet.maintenance_logs(vehicle_id, event_date, service_type, maintenance_cost, mechanic_name, next_service_due)
select v.vehicle_id,
	case 
		when trim(f.event_date) ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(trim(f.event_date), 'YYYY-MM-DD')
	    when trim(f.event_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$' then to_date(trim(f.event_date), 'DD/MM/YYYY')
		when trim(f.event_date) ~ '^\d{1,2}/\d{1,2}/\d{2}$' then to_date(trim(f.event_date), 'DD/MM/YY')
		when trim(f.event_date) ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(trim(f.event_date), 'MM-DD-YYYY')
		else null
	end,
	
	nullif(trim(f.service_type), ''),
	nullif(regexp_replace(trim(f.maintenance_cost), '[^0-9.]', '', 'g'), '')::numeric,
	nullif(upper(trim(f.mechanic_name)), ''),
	
	case 
		when trim(f.next_service_due) ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(trim(f.next_service_due), 'YYYY-MM-DD')
	    when trim(f.next_service_due) ~ '^\d{1,2}/\d{1,2}/\d{4}$' then to_date(trim(f.next_service_due), 'DD/MM/YYYY')
		when trim(f.next_service_due) ~ '^\d{1,2}/\d{1,2}/\d{2}$' then to_date(trim(f.next_service_due), 'DD/MM/YY')
		when trim(f.next_service_due) ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(trim(f.next_service_due), 'MM-DD-YYYY')
		else null
	end
	from fleet_staging f 
	join fleet.vehicles v 
	on v.plate_number = upper(regexp_replace(trim(f.vehicle_plate), '[^A-Za-z0-9]', '', 'g'))
	where lower(trim(f.event_type)) = 'maintenance';

-- ============================================================================================================================
--6. LOAD TRIPS
-- ============================================================================================================================
insert into booking.trips(trip_id, customer_id, driver_id, vehicle_id, pickup_area, dropoff_area, trip_date, pickup_time, distance_km, payment_method, status, fare_amount, customer_rating)
	
	select distinct on (t.trip_id)
		t.trip_id,
		c.customer_id,
		d.driver_id,
		v.vehicle_id,
	
		case 
			when initcap(trim(t.pickup_area)) = 'Westllands' then 'WESTLANDS'
			when initcap(trim(t.pickup_area)) = 'Kasarrani' then 'KASARANI'
			when upper(trim(t.pickup_area)) = 'CBBD' then 'CBD'
			when initcap(trim(t.pickup_area)) = 'Kilimmani' then 'KILIMANI'
			when initcap(trim(t.pickup_area)) = 'Parkllands' then 'PARKLANDS'
			when initcap(trim(t.pickup_area)) = 'Langgata' then 'LANGATA'
			when initcap(trim(t.pickup_area)) = 'Soutth C' then 'SOUTH C'
			when initcap(trim(t.pickup_area)) = 'Lavinngton' then 'LAVINGTON'
			when initcap(trim(t.pickup_area)) = 'Runnda' then 'RUNDA'
			else upper(trim(t.pickup_area)) 
		end,
	
		case 
			when initcap(trim(dropoff_area)) = 'Parkllands' then 'PARKLANDS'
			when initcap(trim(dropoff_area)) = 'Embakkasi' then 'Embakasi'
			when initcap(trim(dropoff_area)) = 'Soutth C' then 'SOUTH C'
			when initcap(trim(dropoff_area)) = 'Runnda' then 'RUNDA'
			when initcap(trim(dropoff_area)) = 'Langgata' then 'LANGATA'
			when initcap(trim(dropoff_area)) = 'Westllands' then 'WESTLANDS'
			when initcap(trim(dropoff_area)) = 'Lavinngton' then 'LAVINGTON'
			when initcap(trim(dropoff_area)) = 'Kilimmani' then 'KILIMANI'
			when upper(trim(dropoff_area)) = 'CBBD' then 'CBD'
			when initcap(trim(dropoff_area)) = 'Burubburu' then 'BURUBURU'
			when initcap(trim(dropoff_area)) = 'Kasarrani' then 'KASARANI'
			else upper(trim(dropoff_area))
		end,
		
		case
			when trim(t.trip_date) ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(trim(t.trip_date), 'YYYY-MM-DD')
			when trim(t.trip_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$' then to_date(trim(t.trip_date), 'DD/MM/YYYY')
			when trim(t.trip_date) ~ '^\d{1,2}/\d{1,2}/\d{2}$' then to_date(trim(t.trip_date), 'DD/MM/YY')
			when trim(t.trip_date) ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(trim(t.trip_date), 'MM-DD-YYYY')
		    else null
		end,
		
		case 
			when trim(t.pickup_time) ~ '^\d{1,2}:\d{2}(:\d{2})?$' then trim(t.pickup_time)::time
			else null  
		end,
		
		case 
			when trim(t.distance_km) ~ '^[0-9]+(\.[0-9]+)?$' then trim(t.distance_km)::numeric
			else null 
		end,
		
		case 
			when lower(trim(payment_method)) = 'mpesa' then 'M-PESA'
			else UPPER(TRIM(Payment_method))
		end,
		
		case
			when initcap(trim(status)) = 'No-Show' then 'NO SHOW'
			when lower(trim(status)) = 'no-show' then 'NO SHOW'
			when upper(trim(status)) = 'NO-SHOW' then 'NO SHOW'
			when initcap(trim(status)) = 'Complete' then 'COMPLETED'
			else upper(trim(status))
		end,
		
		nullif(regexp_replace(trim(t.fare_amount), '[^0-9.]', '', 'g'), '')::numeric,
		
		case 
			when trim(t.customer_rating) ~ '^[0-9]+(\.[0-9]+)?$' 
			and trim(t.customer_rating)::numeric between 1 and 5 
			then trim(t.customer_rating)::numeric
			else null
		end
		
	from trip_staging t
	
	left join booking.customers c
	on initcap(trim(t.customer_name)) = c.customer_name 
	
	left join booking.drivers d 
	on initcap(trim(t.driver_name)) = d.driver_name 
	
	left join fleet.vehicles v 
	on v.plate_number = upper(regexp_replace(trim(t.vehicle_plate), '[^A-Za-z0-9]', '', 'g'))
	order by t.trip_id, d.driver_id desc, c.customer_id desc;

-- ===============================================================================================================
-- 7. VERIFY LOADED DATA
-- ================================================================================================================
select count(*) as vehicle_count
from fleet.vehicles;

select count(*) as customer_count
from booking.customers;

select count(*) as driver_count
from booking.drivers;

select count(*) as trip_count
from booking.trips;

select count(*) as fuel_log_count
from fleet.fuel_logs;

select count(*) as maintenance_log_count
from fleet.maintenance_logs;

-- =================================================================================================================











