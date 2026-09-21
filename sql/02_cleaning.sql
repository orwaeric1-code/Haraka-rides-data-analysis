</> SQL

-- ==============================================================================================
-- HARAKA RIDES PROJECT
-- 02 - DATA CLEANING & VALIDATION
-- Purpose: Clean and validate raw staging data
-- ==============================================================================================

-- ==============================================================================================
-- 1. PROFILE RAW DATA
-- ==============================================================================================

-- Check trip staging records
select * 
from staging.trip_staging;

-- Check fleet staging records
select * 
from staging.fleet_staging;

-- ==============================================================================================
-- 2. VEHICLE PLATE NORMALIZATION
-- ==============================================================================================

select 
	vehicle_plate,
	upper(trim(vehicle_plate)) as cleaned_vehicle_plate
from staging.trip_staging;
-------------------------------------------------------------------------------------------------
select 
	vehicle_plate,
	upper(trim(vehicle_plate)) as cleaned_vehicle_plate
from staging.fleet_staging;

-- ==============================================================================================
-- 3. VEHICLE RECONCILIATION CHECK
-- ==============================================================================================
-- checking whether one plate has conflicting vehicle information---

SELECT 
    UPPER(REGEXP_REPLACE(TRIM(vehicle_plate), '[^A-Za-z0-9]', '', 'g')) AS cleaned_plate, 
    COUNT(DISTINCT vehicle_make) AS different_makes, 
    COUNT(DISTINCT vehicle_model) AS different_models, 
    COUNT(DISTINCT vehicle_year) AS different_years 
FROM staging.fleet_staging 
GROUP BY UPPER(REGEXP_REPLACE(TRIM(vehicle_plate), '[^A-Za-z0-9]', '', 'g'))
HAVING COUNT(DISTINCT vehicle_make) > 1 
   OR COUNT(DISTINCT vehicle_model) > 1 
   OR COUNT(DISTINCT vehicle_year) > 1;

-- ==============================================================================================
-- 4. NAME STANDARDIZATION
-- ==============================================================================================

select 
	customer_name,
	initcap(trim(customer_name)) as cleaned_name
  initcap(trim(driver_name)) as cleaned_driver_name
from staging.trip_staging;

-- ==============================================================================================
-- 5. PHONE NUMBER CLEANING
-- ==============================================================================================

select driver_phone,
case 
	when driver_phone like '+254%'
	then '0' || substring(regexp_replace(driver_phone, '[^0-9]', '', 'g') from 4)
	else regexp_replace(driver_phone, '[^0-9]', '', 'g') 
end as cleaned_driver_phone
from staging.trip_staging;

-- ==============================================================================================
-- 6. DATE STANDARDIZATION
-- ==============================================================================================

select trip_date,
case 
	when trim(trip_date) ~ '^\d{4}-\d{1,2}-\d{1,2}$' then to_date(trim(trip_date), 'YYYY-MM-DD')
	when trim(trip_date) ~ '^\d{1,2}/\d{1,2}/\d{4}$' then to_date(trim(trip_date), 'DD/MM/YYYY')
	when trim(trip_date) ~ '^\d{1,2}/\d{1,2}/\d{2}$' then to_date(trim(trip_date), 'DD/MM/YY')
	when trim(trip_date) ~ '^\d{1,2}-\d{1,2}-\d{4}$' then to_date(trim(trip_date), 'MM-DD-YYYY')
	else null
end as cleaned_trip_date
from staging.trip_staging;

-- ==============================================================================================
-- 7. CUSTOMER RATING VALIDATION
-- ==============================================================================================

select customer_rating,
case 
	when nullif(trim(customer_rating), '') is not null 
	and customer_rating::numeric between 1 and 5 
	then customer_rating::numeric
	else null
end as cleaned_customer_rating
from staging.trip_staging;

-- ==============================================================================================
-- 8. DISTANCE VALIDATION
-- ==============================================================================================

select distance_km,
case 
	when trim(distance_km) ~ '^-?[0-9]+(\.[0-9]+)?$' and trim(distance_km)::numeric >=0
	then trim(distance_km)::numeric
	else null 
end as cleaned_distance_km  
from staging.trip_staging;

-- ==============================================================================================
-- 9. PICKUP TIME VALIDATION
-- ==============================================================================================

select pickup_time,
	case 
		when trim(pickup_time) ~ '^\d{1,2}:\d{2}(:\d{2})?$' then trim(pickup_time)::time
		else null  
	end as cleaned_pickup_time
from staging.trip_staging;

-- ==========================================================================================
--  10. NUMERIC AND CURRENCY CLEANING
-- ============================================================================================

select 
	fare_amount,
	nullif(regexp_replace(fare_amount, '[^0-9.]', '', 'g'),''
	)::numeric as cleaned_fare_amount
from staging.trip_staging;

-----------------------------------------------------------------------------------------------
select 
	fuel_cost,
	nullif(regexp_replace(fuel_cost, '[^0-9.]', '', 'g'),'')::numeric as cleaned_fuel_cost
from staging.fleet_staging;

-- ============================================================================================
-- 11. CUSTOMER AREA STANDARDIZATION
-- ============================================================================================

select customer_area,
case 
	when trim(upper(customer_area)) = 'CBBD' then 'CBD'
	when trim(initcap(customer_area)) = 'Burubburu' then 'BURUBURU'
	when trim(initcap(customer_area)) = 'Westllands' then 'WESTLANDS'
	when trim(initcap(customer_area)) = 'Runnda' then 'RUNDA'
	when trim(initcap(customer_area)) = 'Parkllands' then 'PARKLANDS'
	when trim(initcap(customer_area)) = 'Kasarrani' then 'KASARANI'
	when trim(initcap(customer_area)) = 'Langgata' then 'LANGATA'
	when trim(initcap(customer_area)) = 'Lavinngton' then 'LAVINGTON'
	else trim(upper(customer_area))
end as cleaned_customer_area
from staging.trip_staging;

-- =============================================================================================
-- 12. DUPLICATE CHECK
-- =============================================================================================
select
    trip_id,
    customer_name,
    customer_phone,
    customer_area,
    driver_name,
    driver_phone,
    vehicle_plate,
    vehicle_make,
    vehicle_model,
    pickup_area,
    dropoff_area,
    trip_date,
    pickup_time,
    distance_km,
    payment_method,
    status,
    fare_amount,
    customer_rating,
    COUNT(*) AS duplicate_count
FROM trip_staging
GROUP BY
    trip_id,
    customer_name,
    customer_phone,
    customer_area,
    driver_name,
    driver_phone,
    vehicle_plate,
    vehicle_make,
    vehicle_model,
    pickup_area,
    dropoff_area,
    trip_date,
    pickup_time,
    distance_km,
    payment_method,
    status,
    fare_amount,
    customer_rating
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- ==================================================================================================













