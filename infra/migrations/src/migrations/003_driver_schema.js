/* eslint-disable */
// Migration: 003_driver_schema

exports.up = (pgm) => {
  pgm.createTable({ schema: 'driver_svc', name: 'driver_profiles' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    user_id: { type: 'uuid', notNull: true, unique: true },
    name: { type: 'varchar(255)', notNull: true },
    phone: { type: 'varchar(20)', notNull: true },
    email: { type: 'varchar(255)' },
    profile_photo_url: { type: 'text' },
    status: {
      type: 'varchar(20)', notNull: true, default: "'OFFLINE'",
      check: "status IN ('OFFLINE','ONLINE','ON_TRIP','ON_BREAK','SUSPENDED')",
    },
    kyc_status: {
      type: 'varchar(20)', notNull: true, default: "'PENDING'",
      check: "kyc_status IN ('PENDING','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','EXPIRED')",
    },
    tier: {
      type: 'varchar(10)', notNull: true, default: "'BRONZE'",
      check: "tier IN ('BRONZE','SILVER','GOLD')",
    },
    rating: { type: 'numeric(3,2)', notNull: true, default: 5.0 },
    total_trips: { type: 'integer', notNull: true, default: 0 },
    total_earnings_paise: { type: 'bigint', notNull: true, default: 0 },
    preferred_language: { type: 'varchar(10)', notNull: true, default: "'en'" },
    preferred_destination_lat: { type: 'numeric(10,7)' },
    preferred_destination_lon: { type: 'numeric(10,7)' },
    preferred_destination_label: { type: 'varchar(255)' },
    preferred_destination_uses_today: { type: 'integer', notNull: true, default: 0 },
    preferred_destination_reset_date: { type: 'date' },
    is_ev_driver: { type: 'boolean', notNull: true, default: false },
    is_active: { type: 'boolean', notNull: true, default: true },
    background_check_passed: { type: 'boolean', notNull: true, default: false },
    background_check_at: { type: 'timestamptz' },
    last_online_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    deleted_at: { type: 'timestamptz' },
  });
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_profiles' }, 'user_id');
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_profiles' }, 'status');
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_profiles' }, 'kyc_status');

  pgm.createTable({ schema: 'driver_svc', name: 'driver_documents' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    driver_id: { type: 'uuid', notNull: true, references: { schema: 'driver_svc', name: 'driver_profiles' }, onDelete: 'CASCADE' },
    type: {
      type: 'varchar(50)', notNull: true,
      check: "type IN ('DRIVING_LICENSE','VEHICLE_RC','VEHICLE_INSURANCE','VEHICLE_PERMIT','POLLUTION_CERTIFICATE','PROFILE_PHOTO','PAN_CARD','AADHAAR','BANK_PASSBOOK')",
    },
    file_path: { type: 'text', notNull: true }, // Supabase Storage path (NOT public URL)
    status: {
      type: 'varchar(20)', notNull: true, default: "'PENDING'",
      check: "status IN ('PENDING','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','EXPIRED')",
    },
    expires_at: { type: 'timestamptz' },
    reviewed_by: { type: 'uuid' },
    review_note: { type: 'text' },
    reviewed_at: { type: 'timestamptz' },
    uploaded_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_documents' }, 'driver_id');
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_documents' }, ['driver_id', 'type']);
  pgm.createIndex({ schema: 'driver_svc', name: 'driver_documents' }, 'expires_at');

  pgm.createTable({ schema: 'driver_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_type: { type: 'varchar(100)', notNull: true },
    topic: { type: 'varchar(200)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    correlation_id: { type: 'uuid', notNull: true },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'driver_svc', name: 'outbox' }, 'published_at');

  pgm.createTrigger({ schema: 'driver_svc', name: 'driver_profiles' }, 'update_driver_profiles_updated_at', {
    when: 'BEFORE', operation: 'UPDATE', function: 'update_updated_at_column', level: 'ROW',
  });
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'driver_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'driver_svc', name: 'driver_documents' });
  pgm.dropTable({ schema: 'driver_svc', name: 'driver_profiles' });
};
