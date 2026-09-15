/* eslint-disable */
// Migration: 005_trip_schema

exports.up = (pgm) => {
  pgm.createTable({ schema: 'trip_svc', name: 'trips' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    rider_id: { type: 'uuid', notNull: true },
    driver_id: { type: 'uuid' },
    vehicle_id: { type: 'uuid' },
    service_type: {
      type: 'varchar(20)', notNull: true,
      check: "service_type IN ('BIKE','AUTO','CAB','PARCEL','DRIVER_HIRE')",
    },
    vehicle_type: {
      type: 'varchar(30)', notNull: true,
      check: "vehicle_type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')",
    },
    status: {
      type: 'varchar(30)', notNull: true, default: "'SEARCHING'",
      check: "status IN ('SEARCHING','DRIVER_ASSIGNED','DRIVER_EN_ROUTE','DRIVER_ARRIVED','IN_PROGRESS','COMPLETED','CANCELLED_BY_RIDER','CANCELLED_BY_DRIVER','CANCELLED_BY_SYSTEM','NO_DRIVER_FOUND')",
    },
    estimated_fare_paise: { type: 'bigint', notNull: true },
    actual_fare_paise: { type: 'bigint' },
    distance_meters: { type: 'integer' },
    duration_seconds: { type: 'integer' },
    // Surge stored as basis points: 150 = 1.5x, 100 = 1.0x (no surge)
    surge_multiplier_bps: { type: 'integer', notNull: true, default: 100 },
    otp_code: { type: 'varchar(6)', notNull: true },
    cancellation_reason: { type: 'varchar(50)' },
    cancellation_note: { type: 'text' },
    cancellation_fee_paise: { type: 'bigint', notNull: true, default: 0 },
    shareable_token: { type: 'varchar(32)', unique: true },
    pooling_group_id: { type: 'uuid' },
    scheduled_for: { type: 'timestamptz' },
    is_pooled: { type: 'boolean', notNull: true, default: false },
    coupon_id: { type: 'uuid' },
    discount_paise: { type: 'bigint', notNull: true, default: 0 },
    corporate_account_id: { type: 'uuid' },
    driver_arrived_at: { type: 'timestamptz' },
    started_at: { type: 'timestamptz' },
    completed_at: { type: 'timestamptz' },
    search_started_at: { type: 'timestamptz' },
    search_attempts: { type: 'integer', notNull: true, default: 0 },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'rider_id');
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'driver_id');
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'status');
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'pooling_group_id');
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'scheduled_for');
  pgm.createIndex({ schema: 'trip_svc', name: 'trips' }, 'created_at');

  // Trip stops (pickup, optional waypoints, drop)
  pgm.createTable({ schema: 'trip_svc', name: 'trip_stops' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    trip_id: { type: 'uuid', notNull: true, references: { schema: 'trip_svc', name: 'trips' }, onDelete: 'CASCADE' },
    stop_order: { type: 'integer', notNull: true }, // 0=pickup, 1,2=waypoints, last=drop
    address: { type: 'text', notNull: true },
    lat: { type: 'numeric(10,7)', notNull: true },
    lon: { type: 'numeric(10,7)', notNull: true },
    arrival_time: { type: 'timestamptz' },
  });
  pgm.addConstraint({ schema: 'trip_svc', name: 'trip_stops' }, 'uq_trip_stop_order', 'UNIQUE (trip_id, stop_order)');
  pgm.createIndex({ schema: 'trip_svc', name: 'trip_stops' }, 'trip_id');

  // In-app chat messages
  pgm.createTable({ schema: 'trip_svc', name: 'chat_messages' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    trip_id: { type: 'uuid', notNull: true, references: { schema: 'trip_svc', name: 'trips' }, onDelete: 'CASCADE' },
    sender_id: { type: 'uuid', notNull: true },
    sender_type: { type: 'varchar(10)', notNull: true, check: "sender_type IN ('RIDER','DRIVER')" },
    message: { type: 'text', notNull: true },
    is_read: { type: 'boolean', notNull: true, default: false },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'trip_svc', name: 'chat_messages' }, 'trip_id');
  pgm.createIndex({ schema: 'trip_svc', name: 'chat_messages' }, 'created_at');

  // Ratings
  pgm.createTable({ schema: 'trip_svc', name: 'ratings' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    trip_id: { type: 'uuid', notNull: true, references: { schema: 'trip_svc', name: 'trips' }, onDelete: 'CASCADE' },
    rater_id: { type: 'uuid', notNull: true },
    rater_type: { type: 'varchar(10)', notNull: true, check: "rater_type IN ('RIDER','DRIVER')" },
    ratee_id: { type: 'uuid', notNull: true },
    score: { type: 'integer', notNull: true, check: 'score >= 1 AND score <= 5' },
    comment: { type: 'text' },
    tip_paise: { type: 'bigint', notNull: true, default: 0 },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.addConstraint({ schema: 'trip_svc', name: 'ratings' }, 'uq_trip_rater', 'UNIQUE (trip_id, rater_id)');
  pgm.createIndex({ schema: 'trip_svc', name: 'ratings' }, 'trip_id');
  pgm.createIndex({ schema: 'trip_svc', name: 'ratings' }, 'ratee_id');

  // Outbox
  pgm.createTable({ schema: 'trip_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_type: { type: 'varchar(100)', notNull: true },
    topic: { type: 'varchar(200)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    correlation_id: { type: 'uuid', notNull: true },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'trip_svc', name: 'outbox' }, 'published_at');

  pgm.createTrigger({ schema: 'trip_svc', name: 'trips' }, 'update_trips_updated_at', {
    when: 'BEFORE', operation: 'UPDATE', function: 'update_updated_at_column', level: 'ROW',
  });
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'trip_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'trip_svc', name: 'ratings' });
  pgm.dropTable({ schema: 'trip_svc', name: 'chat_messages' });
  pgm.dropTable({ schema: 'trip_svc', name: 'trip_stops' });
  pgm.dropTable({ schema: 'trip_svc', name: 'trips' });
};
