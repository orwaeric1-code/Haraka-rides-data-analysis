</> SQL
-- creating staging schemas

create schema if not exists staging;

-- Trips staging table
create table staging.trip_staging(
trip_id TEXT,
customer_name TEXT,
customer_phone TEXT,
customer_area TEXT,
driver_name TEXT,
driver_phone TEXT,
vehicle_plate TEXT,
vehicle_make TEXT,
vehicle_model TEXT,
pickup_area TEXT,
dropoff_area TEXT,
trip_date TEXT,
pickup_time TEXT,
distance_km TEXT,
payment_method TEXT,
status TEXT,
fare_amount TEXT,
customer_rating TEXT
);

-- Fleet staging table
create table staging.fleet_staging(
log_id TEXT,
vehicle_plate TEXT,
vehicle_make TEXT,
vehicle_model TEXT,
vehicle_year TEXT,
vehicle_type TEXT,
vehicle_status TEXT,
event_type TEXT,
event_date TEXT,
litres TEXT,
fuel_cost TEXT,
Odometer_reading TEXT,
station_name TEXT,
service_type TEXT,
maintenance_cost TEXT,
mechanic_name TEXT,
next_service_due TEXT
);
