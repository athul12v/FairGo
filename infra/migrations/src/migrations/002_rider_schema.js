/* eslint-disable */
// Migration: 002_rider_schema
// Creates the rider_svc schema tables

exports.up = (pgm) => {
  // ----------------------------------------------------------
  // RIDER PROFILES
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'rider_svc', name: 'rider_profiles' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    user_id: { type: 'uuid', notNull: true, unique: true },
    name: { type: 'varchar(255)', notNull: true },
    phone: { type: 'varchar(20)', notNull: true },
    email: { type: 'varchar(255)' },
    profile_photo_url: { type: 'text' },
    preferred_language: { type: 'varchar(10)', notNull: true, default: "'en'" },
    rating: { type: 'numeric(3,2)', notNull: true, default: 5.0 },
    total_trips: { type: 'integer', notNull: true, default: 0 },
    is_accessibility_required: { type: 'boolean', notNull: true, default: false },
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    deleted_at: { type: 'timestamptz' },
  });
  pgm.createIndex({ schema: 'rider_svc', name: 'rider_profiles' }, 'user_id');
  pgm.createIndex({ schema: 'rider_svc', name: 'rider_profiles' }, 'phone');

  // ----------------------------------------------------------
  // SAVED PLACES
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'rider_svc', name: 'saved_places' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    rider_id: { type: 'uuid', notNull: true, references: { schema: 'rider_svc', name: 'rider_profiles' }, onDelete: 'CASCADE' },
    label: { type: 'varchar(50)', notNull: true },
    address: { type: 'text', notNull: true },
    lat: { type: 'numeric(10,7)', notNull: true },
    lon: { type: 'numeric(10,7)', notNull: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'rider_svc', name: 'saved_places' }, 'rider_id');

  // ----------------------------------------------------------
  // EMERGENCY CONTACTS
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'rider_svc', name: 'emergency_contacts' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    rider_id: { type: 'uuid', notNull: true, references: { schema: 'rider_svc', name: 'rider_profiles' }, onDelete: 'CASCADE' },
    name: { type: 'varchar(255)', notNull: true },
    phone: { type: 'varchar(20)', notNull: true },
    relationship: { type: 'varchar(50)' },
    notify_on_sos: { type: 'boolean', notNull: true, default: true },
    notify_late_night: { type: 'boolean', notNull: true, default: false },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'rider_svc', name: 'emergency_contacts' }, 'rider_id');

  // Outbox for Kafka events
  pgm.createTable({ schema: 'rider_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_type: { type: 'varchar(100)', notNull: true },
    topic: { type: 'varchar(200)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    correlation_id: { type: 'uuid', notNull: true },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'rider_svc', name: 'outbox' }, 'published_at');
  pgm.createIndex({ schema: 'rider_svc', name: 'outbox' }, 'created_at');

  pgm.createTrigger({ schema: 'rider_svc', name: 'rider_profiles' }, 'update_rider_profiles_updated_at', {
    when: 'BEFORE', operation: 'UPDATE', function: 'update_updated_at_column', level: 'ROW',
  });
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'rider_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'rider_svc', name: 'emergency_contacts' });
  pgm.dropTable({ schema: 'rider_svc', name: 'saved_places' });
  pgm.dropTable({ schema: 'rider_svc', name: 'rider_profiles' });
};
