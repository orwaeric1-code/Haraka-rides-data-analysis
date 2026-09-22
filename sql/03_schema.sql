</> SQL

-- ===========================================================================================
-- HARAKA RIDE PROJECT
-- 03 - DATABASE SCHEMA
-- Purpose: Create clean analytical schemas and tables
-- ===========================================================================================

-- ===========================================================================================
-- 1. CREATE SCHEMAS
-- ===========================================================================================

CREATE SCHEMA IF NOT EXISTS booking;
CREATE SCHEMA IF NOT EXISTS fleet;

-- ===========================================================================================
-- 2. FLEET VEHICLES
-- Canonical vehicle master table where other tables reference it through vehicle_id
-- ===========================================================================================
create table fleet.vehicles( 
vehicle_id SERIAL primary key,
plate_number VARCHAR(20) not null unique,
make VARCHAR(50),
model VARCHAR(50),
vehicle_year INT,
vehicle_type VARCHAR(50),
vehicle_status VARCHAR(50)
);

-- ===========================================================================================
-- 3. FUEL LOGS
-- ===========================================================================================
create table fleet.fuel_logs( 
fuel_log_id SERIAL primary key,
vehicle_id INT not null,
event_date DATE,
litres numeric,
fuel_cost numeric,
odometer_reading numeric,
station_name VARCHAR(100),
  
constraint fk_fuel_vehicle
    foreign key (vehicle_id)
    references fleet.vehicles(vehicle_id));

-- ===========================================================================================
-- 4. MAINTENANCE LOGS
-- ===========================================================================================
create table fleet.maintenance_logs(
maintenance_log_id SERIAL primary key,
vehicle_id INT not null,
event_date DATE,
service_type VARCHAR(100),
maintenance_cost numeric,
mechanic_name VARCHAR(100),
next_service_due DATE,
  
constraint fk_maintenance_vehicle
    foreign key (vehicle_id)
    references vehicles(vehicle_id)
);

-- ============================================================================================
-- 5. CUSTOMERS
-- ============================================================================================
create table booking.customers( 
	customer_id SERIAL primary key,
	customer_name VARCHAR(100) not null,
	customer_phone VARCHAR(30)
	);

-- ============================================================================================
-- 6. DRIVERS
-- ============================================================================================
create table booking.drivers( 
	driver_id SERIAL primary key,
	driver_name VARCHAR(100),
	driver_phone VARCHAR(30)
	);

-- ============================================================================================
-- 7. TRIPS
-- ============================================================================================
create table booking.trips( 
	trip_id VARCHAR(50) primary key,
	customer_id INT,
	driver_id INT,
	vehicle_id INT,
	pickup_area VARCHAR(100),
	dropoff_area VARCHAR(100),
	trip_date DATE,
	pickup_time TIME,
	distance_km numeric,
	payment_method VARCHAR(50),
	status VARCHAR(50),
	fare_amount numeric,
	customer_rating numeric,
  
	foreign key (customer_id)
		references booking.customers(customer_id),
  
	foreign key (driver_id) 
		references booking.drivers(driver_id),
  
	foreign key (vehicle_id)
		references fleet.vehicles(vehicle_id)
	);

-- ============================================================================================















