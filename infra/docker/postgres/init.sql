-- FairGo PostgreSQL Initialization
-- Creates per-service schemas for isolation
-- Each schema = one microservice's exclusive data territory

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Service schemas (each service owns its schema)
CREATE SCHEMA IF NOT EXISTS auth_svc;
CREATE SCHEMA IF NOT EXISTS rider_svc;
CREATE SCHEMA IF NOT EXISTS driver_svc;
CREATE SCHEMA IF NOT EXISTS vehicle_svc;
CREATE SCHEMA IF NOT EXISTS trip_svc;
CREATE SCHEMA IF NOT EXISTS matching_svc;
CREATE SCHEMA IF NOT EXISTS pricing_svc;
CREATE SCHEMA IF NOT EXISTS parcel_svc;
CREATE SCHEMA IF NOT EXISTS driver_booking_svc;
CREATE SCHEMA IF NOT EXISTS payment_svc;
CREATE SCHEMA IF NOT EXISTS wallet_svc;
CREATE SCHEMA IF NOT EXISTS coupon_svc;
CREATE SCHEMA IF NOT EXISTS loyalty_svc;
CREATE SCHEMA IF NOT EXISTS corporate_svc;
CREATE SCHEMA IF NOT EXISTS insurance_svc;
CREATE SCHEMA IF NOT EXISTS safety_svc;
CREATE SCHEMA IF NOT EXISTS notification_svc;
CREATE SCHEMA IF NOT EXISTS support_svc;
CREATE SCHEMA IF NOT EXISTS fraud_svc;
CREATE SCHEMA IF NOT EXISTS analytics_svc;

-- Outbox table pattern (each service has its own, but we declare template here)
-- Individual migrations will create per-schema outbox tables

GRANT ALL PRIVILEGES ON DATABASE fairgo TO fairgo;
GRANT ALL PRIVILEGES ON SCHEMA public TO fairgo;

-- Grant schema permissions
DO $$
DECLARE
  schema_name text;
BEGIN
  FOR schema_name IN
    SELECT unnest(ARRAY[
      'auth_svc', 'rider_svc', 'driver_svc', 'vehicle_svc', 'trip_svc',
      'matching_svc', 'pricing_svc', 'parcel_svc', 'driver_booking_svc',
      'payment_svc', 'wallet_svc', 'coupon_svc', 'loyalty_svc',
      'corporate_svc', 'insurance_svc', 'safety_svc', 'notification_svc',
      'support_svc', 'fraud_svc', 'analytics_svc'
    ])
  LOOP
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA %I TO fairgo', schema_name);
  END LOOP;
END $$;
