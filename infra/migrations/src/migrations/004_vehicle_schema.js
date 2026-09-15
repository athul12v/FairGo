/* eslint-disable */
// Migration: 004_vehicle_schema

exports.up = (pgm) => {
  pgm.createTable({ schema: 'vehicle_svc', name: 'vehicles' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    driver_id: { type: 'uuid', notNull: true },
    type: {
      type: 'varchar(30)', notNull: true,
      check: "type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')",
    },
    make: { type: 'varchar(100)', notNull: true },
    model: { type: 'varchar(100)', notNull: true },
    year: { type: 'integer', notNull: true },
    color: { type: 'varchar(50)', notNull: true },
    license_plate: { type: 'varchar(20)', notNull: true },
    fuel_type: {
      type: 'varchar(20)', notNull: true,
      check: "fuel_type IN ('PETROL','DIESEL','CNG','ELECTRIC','HYBRID')",
    },
    is_ev: { type: 'boolean', notNull: true, default: false },
    seating_capacity: { type: 'integer', notNull: true, default: 4 },
    is_wheelchair_accessible: { type: 'boolean', notNull: true, default: false },
    rc_expires_at: { type: 'timestamptz', notNull: true },
    insurance_expires_at: { type: 'timestamptz', notNull: true },
    permit_expires_at: { type: 'timestamptz' },
    pollution_cert_expires_at: { type: 'timestamptz' },
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    deleted_at: { type: 'timestamptz' },
  });
  pgm.createIndex({ schema: 'vehicle_svc', name: 'vehicles' }, 'driver_id');
  pgm.createIndex({ schema: 'vehicle_svc', name: 'vehicles' }, 'license_plate');
  pgm.createIndex({ schema: 'vehicle_svc', name: 'vehicles' }, 'type');
  pgm.createIndex({ schema: 'vehicle_svc', name: 'vehicles' }, 'insurance_expires_at');
  pgm.createIndex({ schema: 'vehicle_svc', name: 'vehicles' }, 'rc_expires_at');

  pgm.createTrigger({ schema: 'vehicle_svc', name: 'vehicles' }, 'update_vehicles_updated_at', {
    when: 'BEFORE', operation: 'UPDATE', function: 'update_updated_at_column', level: 'ROW',
  });
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'vehicle_svc', name: 'vehicles' });
};
