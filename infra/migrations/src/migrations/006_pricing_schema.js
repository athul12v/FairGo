/* eslint-disable */
// Migration: 006_pricing_schema

exports.up = (pgm) => {
  // Cities
  pgm.createTable({ schema: 'pricing_svc', name: 'cities' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    name: { type: 'varchar(100)', notNull: true },
    state: { type: 'varchar(100)', notNull: true },
    country_code: { type: 'varchar(3)', notNull: true, default: "'IN'" },
    is_active: { type: 'boolean', notNull: true, default: false }, // off by default; ops enables city-by-city
    timezone: { type: 'varchar(50)', notNull: true, default: "'Asia/Kolkata'" },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  // Zones (geofenced areas within a city — PostGIS polygon)
  pgm.createTable({ schema: 'pricing_svc', name: 'zones' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    city_id: { type: 'uuid', notNull: true, references: { schema: 'pricing_svc', name: 'cities' } },
    name: { type: 'varchar(100)', notNull: true },
    geojson: { type: 'text', notNull: true }, // GeoJSON Polygon string
    geometry: { type: 'geometry(Polygon, 4326)' }, // PostGIS for spatial queries
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'pricing_svc', name: 'zones' }, 'city_id');
  // Spatial index for zone lookups
  pgm.sql('CREATE INDEX IF NOT EXISTS zones_geometry_idx ON pricing_svc.zones USING GIST (geometry)');

  // Pricing rules
  pgm.createTable({ schema: 'pricing_svc', name: 'pricing_rules' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    zone_id: { type: 'uuid', references: { schema: 'pricing_svc', name: 'zones' } }, // null = global default
    city_id: { type: 'uuid', references: { schema: 'pricing_svc', name: 'cities' } },
    vehicle_type: {
      type: 'varchar(30)', notNull: true,
      check: "vehicle_type IN ('BIKE','AUTO','CAB_MINI','CAB_SEDAN','CAB_SUV','CAB_ECONOMY','CAB_PREMIUM','PARCEL_BIKE','PARCEL_THREE_WHEELER')",
    },
    base_fare_paise: { type: 'bigint', notNull: true },
    per_km_paise: { type: 'bigint', notNull: true },
    per_minute_paise: { type: 'bigint', notNull: true },
    minimum_fare_paise: { type: 'bigint', notNull: true },
    cancellation_fee_paise: { type: 'bigint', notNull: true, default: 0 },
    cancellation_free_window_seconds: { type: 'integer', notNull: true, default: 120 },
    night_charge_multiplier_bps: { type: 'integer', notNull: true, default: 100 }, // 110 = 1.1x
    night_charge_start_hour: { type: 'integer', notNull: true, default: 22 }, // 10pm
    night_charge_end_hour: { type: 'integer', notNull: true, default: 6 },  // 6am
    valid_from: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    valid_until: { type: 'timestamptz' },
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'pricing_svc', name: 'pricing_rules' }, 'vehicle_type');
  pgm.createIndex({ schema: 'pricing_svc', name: 'pricing_rules' }, 'zone_id');
  pgm.createIndex({ schema: 'pricing_svc', name: 'pricing_rules' }, 'is_active');

  // Surge rules
  pgm.createTable({ schema: 'pricing_svc', name: 'surge_rules' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    zone_id: { type: 'uuid', notNull: true, references: { schema: 'pricing_svc', name: 'zones' } },
    vehicle_type: { type: 'varchar(30)' }, // null = all types in zone
    multiplier_bps: { type: 'integer', notNull: true }, // current active multiplier
    trigger_demand_supply_ratio: { type: 'numeric(5,2)', notNull: true, default: 2.0 },
    max_multiplier_bps: { type: 'integer', notNull: true, default: 300 }, // cap at 3x
    is_active: { type: 'boolean', notNull: true, default: true },
    activated_at: { type: 'timestamptz' },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'pricing_svc', name: 'surge_rules' }, 'zone_id');
  pgm.createIndex({ schema: 'pricing_svc', name: 'surge_rules' }, 'is_active');
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'pricing_svc', name: 'surge_rules' });
  pgm.dropTable({ schema: 'pricing_svc', name: 'pricing_rules' });
  pgm.dropTable({ schema: 'pricing_svc', name: 'zones' });
  pgm.dropTable({ schema: 'pricing_svc', name: 'cities' });
};
