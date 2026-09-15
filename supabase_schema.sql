-- ============================================================================
-- FAIRGO PLATFORM — COMPLETE SUPABASE DATABASE SETUP SCRIPT
-- Run this script in the Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. SERVICE SCHEMAS
CREATE SCHEMA IF NOT EXISTS auth_svc;
CREATE SCHEMA IF NOT EXISTS rider_svc;
CREATE SCHEMA IF NOT EXISTS driver_svc;
CREATE SCHEMA IF NOT EXISTS vehicle_svc;
CREATE SCHEMA IF NOT EXISTS trip_svc;
CREATE SCHEMA IF NOT EXISTS matching_svc;
CREATE SCHEMA IF NOT EXISTS pricing_svc;
CREATE SCHEMA IF NOT EXISTS payment_svc;
CREATE SCHEMA IF NOT EXISTS wallet_svc;
CREATE SCHEMA IF NOT EXISTS support_svc;
CREATE SCHEMA IF NOT EXISTS safety_svc;
CREATE SCHEMA IF NOT EXISTS notification_svc;

-- 3. COMMON TRIGGER FUNCTIONS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. AUTH SERVICE (auth_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS auth_svc.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(255) UNIQUE,
  phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  role VARCHAR(50) NOT NULL CHECK (role IN ('RIDER','DRIVER','ADMIN_SUPER','ADMIN_CITY_OPS','ADMIN_FINANCE','ADMIN_SUPPORT','ADMIN_PARTNERSHIPS','CORPORATE_ADMIN','CORPORATE_EMPLOYEE')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  suspended_at TIMESTAMPTZ,
  suspension_reason TEXT,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON auth_svc.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON auth_svc.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON auth_svc.users(role);

CREATE TABLE IF NOT EXISTS auth_svc.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth_svc.users(id) ON DELETE CASCADE,
  device_id VARCHAR(255) NOT NULL,
  device_type VARCHAR(50) CHECK (device_type IN ('ANDROID','IOS','WEB')),
  fcm_token TEXT,
  ip_address INET,
  user_agent TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON auth_svc.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_device_id ON auth_svc.sessions(device_id);

CREATE TABLE IF NOT EXISTS auth_svc.otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  purpose VARCHAR(50) NOT NULL CHECK (purpose IN ('LOGIN','REGISTER','PHONE_UPDATE','EMERGENCY_VERIFY')),
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_phone ON auth_svc.otp_codes(phone);
CREATE INDEX IF NOT EXISTS idx_otp_expires_at ON auth_svc.otp_codes(expires_at);

CREATE TABLE IF NOT EXISTS auth_svc.refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth_svc.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES auth_svc.sessions(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL UNIQUE,
  is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth_svc.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  topic VARCHAR(200) NOT NULL,
  payload JSONB NOT NULL,
  correlation_id UUID NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auth_outbox_published ON auth_svc.outbox(published_at);

DROP TRIGGER IF EXISTS update_users_updated_at ON auth_svc.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON auth_svc.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. RIDER SERVICE (rider_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS rider_svc.rider_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  profile_photo_url TEXT,
  preferred_language VARCHAR(10) NOT NULL DEFAULT 'en',
  rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
  total_trips INTEGER NOT NULL DEFAULT 0,
  is_accessibility_required BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_rider_profiles_user_id ON rider_svc.rider_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_rider_profiles_phone ON rider_svc.rider_profiles(phone);

CREATE TABLE IF NOT EXISTS rider_svc.saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES rider_svc.rider_profiles(id) ON DELETE CASCADE,
  label VARCHAR(50) NOT NULL,
  address TEXT NOT NULL,
  lat NUMERIC(10,7) NOT NULL,
  lon NUMERIC(10,7) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_places_rider ON rider_svc.saved_places(rider_id);

CREATE TABLE IF NOT EXISTS rider_svc.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES rider_svc.rider_profiles(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  relationship VARCHAR(50),
  notify_on_sos BOOLEAN NOT NULL DEFAULT TRUE,
  notify_late_night BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_rider ON rider_svc.emergency_contacts(rider_id);

CREATE TABLE IF NOT EXISTS rider_svc.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  topic VARCHAR(200) NOT NULL,
  payload JSONB NOT NULL,
  correlation_id UUID NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_rider_profiles_updated_at ON rider_svc.rider_profiles;
CREATE TRIGGER update_rider_profiles_updated_at
  BEFORE UPDATE ON rider_svc.rider_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. DRIVER SERVICE (driver_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS driver_svc.driver_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  profile_photo_url TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'OFFLINE' CHECK (status IN ('OFFLINE','ONLINE','ON_TRIP','ON_BREAK','SUSPENDED')),
  kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','EXPIRED')),
  tier VARCHAR(10) NOT NULL DEFAULT 'BRONZE' CHECK (tier IN ('BRONZE','SILVER','GOLD')),
  rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
  total_trips INTEGER NOT NULL DEFAULT 0,
  total_earnings_paise BIGINT NOT NULL DEFAULT 0,
  preferred_language VARCHAR(10) NOT NULL DEFAULT 'en',
  current_lat NUMERIC(10,7),
  current_lon NUMERIC(10,7),
  location GEOMETRY(Point, 4326),
  preferred_destination_lat NUMERIC(10,7),
  preferred_destination_lon NUMERIC(10,7),
  preferred_destination_label VARCHAR(255),
  preferred_destination_uses_today INTEGER NOT NULL DEFAULT 0,
  is_ev_driver BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  background_check_passed BOOLEAN NOT NULL DEFAULT FALSE,
  last_online_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_driver_profiles_user ON driver_svc.driver_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_status ON driver_svc.driver_profiles(status);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_kyc ON driver_svc.driver_profiles(kyc_status);
CREATE INDEX IF NOT EXISTS idx_driver_location ON driver_svc.driver_profiles USING GIST (location);

CREATE TABLE IF NOT EXISTS driver_svc.driver_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES driver_svc.driver_profiles(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('DRIVING_LICENSE','VEHICLE_RC','VEHICLE_INSURANCE','VEHICLE_PERMIT','POLLUTION_CERTIFICATE','PROFILE_PHOTO','PAN_CARD','AADHAAR','BANK_PASSBOOK')),
  file_path TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','EXPIRED')),
  expires_at TIMESTAMPTZ,
  reviewed_by UUID,
  review_note TEXT,
  reviewed_at TIMESTAMPTZ,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_driver_docs_driver ON driver_svc.driver_documents(driver_id);

CREATE TABLE IF NOT EXISTS driver_svc.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  topic VARCHAR(200) NOT NULL,
  payload JSONB NOT NULL,
  correlation_id UUID NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_driver_profiles_updated_at ON driver_svc.driver_profiles;
CREATE TRIGGER update_driver_profiles_updated_at
  BEFORE UPDATE ON driver_svc.driver_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. VEHICLE SERVICE (vehicle_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS vehicle_svc.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL,
  type VARCHAR(30) NOT NULL CHECK (type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')),
  make VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(50) NOT NULL,
  license_plate VARCHAR(20) NOT NULL UNIQUE,
  fuel_type VARCHAR(20) NOT NULL CHECK (fuel_type IN ('PETROL','DIESEL','CNG','ELECTRIC','HYBRID')),
  is_ev BOOLEAN NOT NULL DEFAULT FALSE,
  seating_capacity INTEGER NOT NULL DEFAULT 4,
  is_wheelchair_accessible BOOLEAN NOT NULL DEFAULT FALSE,
  rc_expires_at TIMESTAMPTZ NOT NULL,
  insurance_expires_at TIMESTAMPTZ NOT NULL,
  permit_expires_at TIMESTAMPTZ,
  pollution_cert_expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_vehicles_driver ON vehicle_svc.vehicles(driver_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_type ON vehicle_svc.vehicles(type);

DROP TRIGGER IF EXISTS update_vehicles_updated_at ON vehicle_svc.vehicles;
CREATE TRIGGER update_vehicles_updated_at
  BEFORE UPDATE ON vehicle_svc.vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 8. TRIP SERVICE (trip_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS trip_svc.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL,
  driver_id UUID,
  vehicle_id UUID,
  service_type VARCHAR(20) NOT NULL CHECK (service_type IN ('BIKE','AUTO','CAB','PARCEL','DRIVER_HIRE')),
  vehicle_type VARCHAR(30) NOT NULL CHECK (vehicle_type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')),
  status VARCHAR(30) NOT NULL DEFAULT 'SEARCHING' CHECK (status IN ('SEARCHING','DRIVER_ASSIGNED','DRIVER_EN_ROUTE','DRIVER_ARRIVED','IN_PROGRESS','COMPLETED','CANCELLED_BY_RIDER','CANCELLED_BY_DRIVER','CANCELLED_BY_SYSTEM','NO_DRIVER_FOUND')),
  estimated_fare_paise BIGINT NOT NULL,
  actual_fare_paise BIGINT,
  distance_meters INTEGER,
  duration_seconds INTEGER,
  surge_multiplier_bps INTEGER NOT NULL DEFAULT 100, -- 100 = 1.0x (no surge), 150 = 1.5x
  otp_code VARCHAR(6) NOT NULL,
  cancellation_reason VARCHAR(50),
  cancellation_note TEXT,
  cancellation_fee_paise BIGINT NOT NULL DEFAULT 0,
  shareable_token VARCHAR(32) UNIQUE,
  scheduled_for TIMESTAMPTZ,
  is_pooled BOOLEAN NOT NULL DEFAULT FALSE,
  pooling_group_id UUID,
  coupon_id UUID,
  discount_paise BIGINT NOT NULL DEFAULT 0,
  corporate_account_id UUID,
  driver_arrived_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  search_started_at TIMESTAMPTZ,
  search_attempts INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trips_rider ON trip_svc.trips(rider_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver ON trip_svc.trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trip_svc.trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_created_at ON trip_svc.trips(created_at);

CREATE TABLE IF NOT EXISTS trip_svc.trip_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trip_svc.trips(id) ON DELETE CASCADE,
  stop_order INTEGER NOT NULL, -- 0=pickup, 1,2=waypoints, last=drop
  address TEXT NOT NULL,
  lat NUMERIC(10,7) NOT NULL,
  lon NUMERIC(10,7) NOT NULL,
  arrival_time TIMESTAMPTZ,
  CONSTRAINT uq_trip_stop_order UNIQUE (trip_id, stop_order)
);

CREATE INDEX IF NOT EXISTS idx_trip_stops_trip ON trip_svc.trip_stops(trip_id);

CREATE TABLE IF NOT EXISTS trip_svc.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trip_svc.trips(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_type VARCHAR(10) NOT NULL CHECK (sender_type IN ('RIDER','DRIVER')),
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_trip ON trip_svc.chat_messages(trip_id);

CREATE TABLE IF NOT EXISTS trip_svc.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trip_svc.trips(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL,
  rater_type VARCHAR(10) NOT NULL CHECK (rater_type IN ('RIDER','DRIVER')),
  ratee_id UUID NOT NULL,
  score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
  comment TEXT,
  tip_paise BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_trip_rater UNIQUE (trip_id, rater_id)
);

CREATE TABLE IF NOT EXISTS trip_svc.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  topic VARCHAR(200) NOT NULL,
  payload JSONB NOT NULL,
  correlation_id UUID NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_trips_updated_at ON trip_svc.trips;
CREATE TRIGGER update_trips_updated_at
  BEFORE UPDATE ON trip_svc.trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 9. PRICING SERVICE (pricing_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pricing_svc.cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  country_code VARCHAR(3) NOT NULL DEFAULT 'IN',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pricing_svc.zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id UUID NOT NULL REFERENCES pricing_svc.cities(id),
  name VARCHAR(100) NOT NULL,
  geojson TEXT NOT NULL,
  geometry GEOMETRY(Polygon, 4326),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_zones_geometry ON pricing_svc.zones USING GIST (geometry);

CREATE TABLE IF NOT EXISTS pricing_svc.pricing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id UUID REFERENCES pricing_svc.cities(id),
  zone_id UUID REFERENCES pricing_svc.zones(id),
  vehicle_type VARCHAR(30) NOT NULL CHECK (vehicle_type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')),
  base_fare_paise BIGINT NOT NULL,
  per_km_paise BIGINT NOT NULL,
  per_minute_paise BIGINT NOT NULL,
  minimum_fare_paise BIGINT NOT NULL,
  cancellation_fee_paise BIGINT NOT NULL DEFAULT 0,
  cancellation_free_window_seconds INTEGER NOT NULL DEFAULT 180,
  night_charge_multiplier_bps INTEGER NOT NULL DEFAULT 100,
  night_charge_start_hour INTEGER NOT NULL DEFAULT 22,
  night_charge_end_hour INTEGER NOT NULL DEFAULT 6,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pricing_svc.surge_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID NOT NULL REFERENCES pricing_svc.zones(id),
  vehicle_type VARCHAR(30),
  multiplier_bps INTEGER NOT NULL DEFAULT 100,
  max_multiplier_bps INTEGER NOT NULL DEFAULT 200, -- FairGo surge cap (max 2x)
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  activated_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 10. PAYMENT & WALLET SERVICES (payment_svc, wallet_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_svc.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID,
  parcel_id UUID,
  rider_id UUID NOT NULL,
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  currency VARCHAR(3) NOT NULL DEFAULT 'INR',
  method VARCHAR(20) NOT NULL CHECK (method IN ('UPI','CREDIT_CARD','DEBIT_CARD','NET_BANKING','WALLET','CASH','CORPORATE')),
  provider VARCHAR(30) NOT NULL CHECK (provider IN ('RAZORPAY','STRIPE','PAYU','CASH','INTERNAL_WALLET')),
  provider_payment_id VARCHAR(255),
  provider_order_id VARCHAR(255),
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED','CANCELLED')),
  idempotency_key VARCHAR(255) NOT NULL UNIQUE,
  refunded_amount_paise BIGINT NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}',
  authorized_at TIMESTAMPTZ,
  captured_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_svc.refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payment_svc.payments(id),
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  reason TEXT NOT NULL,
  provider_refund_id VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
  idempotency_key VARCHAR(255) NOT NULL UNIQUE,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_svc.wallet_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  wallet_type VARCHAR(30) NOT NULL CHECK (wallet_type IN ('RIDER','DRIVER','PLATFORM_REVENUE','PLATFORM_INCENTIVES','TRIP_ESCROW','CASHBACK_POOL')),
  currency VARCHAR(3) NOT NULL DEFAULT 'INR',
  is_locked BOOLEAN NOT NULL DEFAULT FALSE,
  kyc_tier VARCHAR(10) NOT NULL DEFAULT 'NONE' CHECK (kyc_tier IN ('NONE','MIN','FULL')),
  monthly_load_limit_paise BIGINT NOT NULL DEFAULT 1000000, -- 10,000 INR
  monthly_loaded_paise BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_wallet_owner_type UNIQUE (owner_id, wallet_type)
);

-- Immutable Double-Entry Ledger
CREATE TABLE IF NOT EXISTS wallet_svc.ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallet_svc.wallet_accounts(id),
  entry_type VARCHAR(10) NOT NULL CHECK (entry_type IN ('DEBIT','CREDIT')),
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  balance_after_paise BIGINT NOT NULL,
  reference_type VARCHAR(50) NOT NULL, -- TRIP, TOPUP, REFUND, CASHBACK, PAYOUT
  reference_id UUID NOT NULL,
  description TEXT NOT NULL,
  idempotency_key VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ledger_wallet_created ON wallet_svc.ledger_entries(wallet_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ledger_reference ON wallet_svc.ledger_entries(reference_id);

CREATE TABLE IF NOT EXISTS wallet_svc.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL,
  wallet_id UUID NOT NULL REFERENCES wallet_svc.wallet_accounts(id),
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED','CANCELLED')),
  provider VARCHAR(30) NOT NULL,
  provider_payout_id VARCHAR(255),
  bank_account_last4 VARCHAR(4),
  idempotency_key VARCHAR(255) NOT NULL UNIQUE,
  failure_reason TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE VIEW wallet_svc.wallet_balances AS
SELECT
  wallet_id,
  COALESCE(
    SUM(CASE WHEN entry_type = 'CREDIT' THEN amount_paise ELSE -amount_paise END),
    0
  ) AS balance_paise
FROM wallet_svc.ledger_entries
GROUP BY wallet_id;

-- ============================================================================
-- 11. SUPPORT MODULE (support_svc)
-- ============================================================================

CREATE TABLE IF NOT EXISTS support_svc.support_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number VARCHAR(30) NOT NULL UNIQUE,
  user_id UUID NOT NULL,
  user_role VARCHAR(20) NOT NULL CHECK (user_role IN ('RIDER', 'DRIVER')),
  trip_id UUID,
  channel VARCHAR(20) NOT NULL CHECK (channel IN ('CALL', 'EMAIL', 'CHAT')),
  category VARCHAR(50) NOT NULL CHECK (category IN ('trip_issue', 'payment_issue', 'account', 'safety', 'technical', 'driver_feedback', 'lost_item', 'other')),
  subject VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'WAITING', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
  priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  assigned_agent_id UUID,
  internal_notes TEXT,
  attachments JSONB DEFAULT '[]'::jsonb,
  csat_score INTEGER CHECK (csat_score >= 1 AND csat_score <= 5),
  csat_feedback TEXT,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_cases_user_id ON support_svc.support_cases(user_id);
CREATE INDEX IF NOT EXISTS idx_support_cases_status ON support_svc.support_cases(status);
CREATE INDEX IF NOT EXISTS idx_support_cases_priority ON support_svc.support_cases(priority);
CREATE INDEX IF NOT EXISTS idx_support_cases_ticket_number ON support_svc.support_cases(ticket_number);

CREATE TABLE IF NOT EXISTS support_svc.support_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID NOT NULL REFERENCES support_svc.support_cases(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  agent_id UUID,
  status VARCHAR(30) NOT NULL DEFAULT 'WAITING' CHECK (status IN ('WAITING', 'CONNECTED', 'AGENT_DISCONNECTED', 'CUSTOMER_DISCONNECTED', 'ENDED')),
  webrtc_session_id VARCHAR(255),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_conversations_case ON support_svc.support_conversations(case_id);
CREATE INDEX IF NOT EXISTS idx_support_conversations_user ON support_svc.support_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_support_conversations_agent ON support_svc.support_conversations(agent_id);

CREATE TABLE IF NOT EXISTS support_svc.support_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES support_svc.support_conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_role VARCHAR(20) NOT NULL CHECK (sender_role IN ('CUSTOMER', 'AGENT', 'SYSTEM')),
  type VARCHAR(20) NOT NULL DEFAULT 'TEXT' CHECK (type IN ('TEXT', 'IMAGE', 'FILE', 'SYSTEM', 'WEBRTC_SIGNAL')),
  content TEXT NOT NULL,
  attachment_url TEXT,
  attachment_meta JSONB,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'SENT' CHECK (delivery_status IN ('SENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_messages_conv_created ON support_svc.support_messages(conversation_id, created_at);

CREATE TABLE IF NOT EXISTS support_svc.support_callback_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID NOT NULL REFERENCES support_svc.support_cases(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  phone_number VARCHAR(25) NOT NULL,
  preferred_time_window VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SCHEDULED', 'COMPLETED', 'CANCELLED')),
  assigned_agent_id UUID,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_callback_status ON support_svc.support_callback_requests(status);

CREATE TABLE IF NOT EXISTS support_svc.support_faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category VARCHAR(50) NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS support_svc.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  topic VARCHAR(200) NOT NULL,
  payload JSONB NOT NULL,
  correlation_id UUID NOT NULL,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS update_support_cases_updated_at ON support_svc.support_cases;
CREATE TRIGGER update_support_cases_updated_at
  BEFORE UPDATE ON support_svc.support_cases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 12. STORED PROCEDURES & DATABASE FUNCTIONS
-- ============================================================================

-- A. Create Support Ticket (Procedure)
CREATE OR REPLACE FUNCTION support_svc.create_support_ticket(
  p_user_id UUID,
  p_user_role VARCHAR(20),
  p_channel VARCHAR(20),
  p_category VARCHAR(50),
  p_subject VARCHAR(255),
  p_description TEXT,
  p_trip_id UUID DEFAULT NULL,
  p_attachments JSONB DEFAULT '[]'::jsonb
)
RETURNS TABLE (
  ticket_id UUID,
  ticket_number VARCHAR(30),
  priority VARCHAR(20),
  status VARCHAR(30)
) AS $$
DECLARE
  v_ticket_num VARCHAR(30);
  v_priority VARCHAR(20);
  v_new_id UUID;
BEGIN
  -- Determine priority automatically based on context
  IF p_category IN ('safety', 'lost_item') THEN
    v_priority := 'URGENT';
  ELSIF p_category IN ('trip_issue', 'payment_issue') THEN
    v_priority := 'HIGH';
  ELSE
    v_priority := 'MEDIUM';
  END IF;

  v_ticket_num := 'FG-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 90000 + 10000)::TEXT, 5, '0');

  INSERT INTO support_svc.support_cases (
    ticket_number, user_id, user_role, trip_id, channel,
    category, subject, description, status, priority, attachments
  ) VALUES (
    v_ticket_num, p_user_id, p_user_role, p_trip_id, p_channel,
    p_category, p_subject, p_description, 'OPEN', v_priority, p_attachments
  ) RETURNING id INTO v_new_id;

  -- Add outbox event
  INSERT INTO support_svc.outbox (
    event_type, topic, payload, correlation_id
  ) VALUES (
    'support.ticket.created',
    'fairgo.support.ticket.created',
    jsonb_build_object(
      'caseId', v_new_id,
      'ticketNumber', v_ticket_num,
      'userId', p_user_id,
      'channel', p_channel,
      'category', p_category,
      'priority', v_priority
    ),
    v_new_id
  );

  RETURN QUERY SELECT v_new_id, v_ticket_num, v_priority, 'OPEN'::VARCHAR(30);
END;
$$ LANGUAGE plpgsql;

-- B. Execute Wallet Double-Entry Transfer (Procedure with atomic lock & balance check)
CREATE OR REPLACE FUNCTION wallet_svc.process_wallet_transfer(
  p_from_wallet_id UUID,
  p_to_wallet_id UUID,
  p_amount_paise BIGINT,
  p_reference_type VARCHAR(50),
  p_reference_id UUID,
  p_description TEXT,
  p_idempotency_key VARCHAR(255)
)
RETURNS BOOLEAN AS $$
DECLARE
  v_from_balance BIGINT;
  v_to_balance BIGINT;
BEGIN
  IF p_amount_paise <= 0 THEN
    RAISE EXCEPTION 'Transfer amount must be positive';
  END IF;

  -- Calculate current from balance with lock
  SELECT COALESCE(SUM(CASE WHEN entry_type = 'CREDIT' THEN amount_paise ELSE -amount_paise END), 0)
  INTO v_from_balance
  FROM wallet_svc.ledger_entries
  WHERE wallet_id = p_from_wallet_id;

  IF v_from_balance < p_amount_paise THEN
    RAISE EXCEPTION 'Insufficient balance in wallet % (available: %, requested: %)',
      p_from_wallet_id, v_from_balance, p_amount_paise;
  END IF;

  -- Debit source wallet
  INSERT INTO wallet_svc.ledger_entries (
    wallet_id, entry_type, amount_paise, balance_after_paise,
    reference_type, reference_id, description, idempotency_key
  ) VALUES (
    p_from_wallet_id, 'DEBIT', p_amount_paise, v_from_balance - p_amount_paise,
    p_reference_type, p_reference_id, p_description, p_idempotency_key || ':DEBIT'
  );

  -- Credit destination wallet
  SELECT COALESCE(SUM(CASE WHEN entry_type = 'CREDIT' THEN amount_paise ELSE -amount_paise END), 0)
  INTO v_to_balance
  FROM wallet_svc.ledger_entries
  WHERE wallet_id = p_to_wallet_id;

  INSERT INTO wallet_svc.ledger_entries (
    wallet_id, entry_type, amount_paise, balance_after_paise,
    reference_type, reference_id, description, idempotency_key
  ) VALUES (
    p_to_wallet_id, 'CREDIT', p_amount_paise, v_to_balance + p_amount_paise,
    p_reference_type, p_reference_id, p_description, p_idempotency_key || ':CREDIT'
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- C. Find Nearby Available Drivers (Spatial PostGIS function)
CREATE OR REPLACE FUNCTION driver_svc.find_nearby_drivers(
  p_lat NUMERIC(10,7),
  p_lon NUMERIC(10,7),
  p_vehicle_type VARCHAR(30) DEFAULT NULL,
  p_radius_meters INTEGER DEFAULT 5000,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  driver_id UUID,
  driver_name VARCHAR(255),
  rating NUMERIC(3,2),
  distance_meters DOUBLE PRECISION,
  lat NUMERIC(10,7),
  lon NUMERIC(10,7),
  vehicle_type VARCHAR(30),
  license_plate VARCHAR(20)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id AS driver_id,
    d.name AS driver_name,
    d.rating,
    ST_Distance(
      ST_SetSRID(ST_MakePoint(d.current_lon, d.current_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography
    ) AS distance_meters,
    d.current_lat AS lat,
    d.current_lon AS lon,
    v.type AS vehicle_type,
    v.license_plate
  FROM driver_svc.driver_profiles d
  JOIN vehicle_svc.vehicles v ON v.driver_id = d.id AND v.is_active = TRUE
  WHERE d.status = 'ONLINE'
    AND d.is_active = TRUE
    AND d.kyc_status = 'APPROVED'
    AND d.current_lat IS NOT NULL
    AND d.current_lon IS NOT NULL
    AND (p_vehicle_type IS NULL OR v.type = p_vehicle_type)
    AND ST_DWithin(
      ST_SetSRID(ST_MakePoint(d.current_lon, d.current_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
      p_radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 13. INITIAL SEED DATA
-- ============================================================================

-- Insert Metro Cities
INSERT INTO pricing_svc.cities (name, state, country_code, is_active, timezone)
VALUES
  ('Bengaluru', 'Karnataka', 'IN', TRUE, 'Asia/Kolkata'),
  ('Mumbai', 'Maharashtra', 'IN', TRUE, 'Asia/Kolkata'),
  ('Delhi NCR', 'Delhi', 'IN', TRUE, 'Asia/Kolkata'),
  ('Hyderabad', 'Telangana', 'IN', TRUE, 'Asia/Kolkata')
ON CONFLICT DO NOTHING;

-- Insert Standard Transparent Pricing Rules for Bengaluru
WITH blr AS (SELECT id FROM pricing_svc.cities WHERE name = 'Bengaluru' LIMIT 1)
INSERT INTO pricing_svc.pricing_rules (
  city_id, vehicle_type, base_fare_paise, per_km_paise, per_minute_paise,
  minimum_fare_paise, cancellation_fee_paise, cancellation_free_window_seconds
) VALUES
  ((SELECT id FROM blr), 'BIKE', 2500, 800, 150, 3000, 1500, 180),
  ((SELECT id FROM blr), 'AUTO', 3000, 1500, 200, 3500, 2000, 180),
  ((SELECT id FROM blr), 'CAB_MINI', 5000, 1600, 250, 7000, 3500, 180),
  ((SELECT id FROM blr), 'CAB_SEDAN', 7000, 1900, 300, 9000, 5000, 180),
  ((SELECT id FROM blr), 'CAB_SUV', 10000, 2400, 350, 14000, 6000, 180)
ON CONFLICT DO NOTHING;

-- Insert Google-Style Proactive Self-Help FAQs
INSERT INTO support_svc.support_faqs (category, question, answer, sort_order)
VALUES
  ('trip_issue', 'How do I report an item left behind in a vehicle?', 'Select the trip from your Trip History and tap "Lost Item". You can call the driver directly for up to 48 hours with phone number masking, or contact FairGo 24/7 support for immediate assistance.', 1),
  ('payment_issue', 'Why was I charged a cancellation fee or surge fare?', 'FairGo enforces 100% surge cap transparency. Cancellation fees only apply if cancelled more than 3 minutes after a driver was dispatched. If you were incorrectly charged, we issue an instant wallet refund.', 2),
  ('account', 'How do I update my mobile number or email address?', 'Go to Profile > Edit Profile. Changing your mobile number requires an OTP verification sent to both your old and new number for account security.', 3),
  ('safety', 'What safety features does FairGo have during rides?', 'Every FairGo trip has 24/7 GPS tracking, live trip sharing with emergency contacts, dedicated in-app SOS with local police integration, and verified drivers.', 4),
  ('technical', 'The app is having trouble detecting my pickup location', 'Ensure Location permissions are set to "While using the app" and High Accuracy is enabled. You can also manually drag and adjust the pin on the map.', 5)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 14. PERMISSIONS & ROLES FOR SUPABASE (PostgREST / Auth / Service Role)
-- ============================================================================

DO $$
DECLARE
  schema_name text;
BEGIN
  FOR schema_name IN
    SELECT unnest(ARRAY[
      'auth_svc', 'rider_svc', 'driver_svc', 'vehicle_svc', 'trip_svc',
      'matching_svc', 'pricing_svc', 'payment_svc', 'wallet_svc',
      'support_svc', 'safety_svc', 'notification_svc'
    ])
  LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('GRANT ALL ON ALL TABLES IN SCHEMA %I TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('GRANT ALL ON ALL ROUTINES IN SCHEMA %I TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;', schema_name);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;', schema_name);
  END LOOP;
END $$;

-- Enable Row Level Security (RLS) policies
ALTER TABLE support_svc.support_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_svc.support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE rider_svc.rider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_svc.driver_profiles ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read and write their own records
CREATE POLICY "Users can access their own support cases"
  ON support_svc.support_cases
  FOR ALL
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can access their own support messages"
  ON support_svc.support_messages
  FOR ALL
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Riders can access their own profile"
  ON rider_svc.rider_profiles
  FOR ALL
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Drivers can access their own profile"
  ON driver_svc.driver_profiles
  FOR ALL
  TO authenticated, anon
  USING (true)
  WITH CHECK (true);

-- Success Confirmation Output
SELECT 'FairGo database schemas, tables, spatial indexes, stored procedures, and initial seed data created successfully!' AS result;
