/* eslint-disable */
// Migration: 001_auth_schema
// Creates the auth_svc schema tables

exports.up = (pgm) => {
  // ----------------------------------------------------------
  // USERS (auth service owns this table)
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'auth_svc', name: 'users' }, {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('gen_random_uuid()'),
    },
    phone: {
      type: 'varchar(20)',
      unique: true,
    },
    email: {
      type: 'varchar(255)',
      unique: true,
    },
    phone_verified: {
      type: 'boolean',
      notNull: true,
      default: false,
    },
    email_verified: {
      type: 'boolean',
      notNull: true,
      default: false,
    },
    role: {
      type: 'varchar(50)',
      notNull: true,
      check: "role IN ('RIDER','DRIVER','ADMIN_SUPER','ADMIN_CITY_OPS','ADMIN_FINANCE','ADMIN_SUPPORT','ADMIN_PARTNERSHIPS','CORPORATE_ADMIN','CORPORATE_EMPLOYEE')",
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true,
    },
    suspended_at: {
      type: 'timestamptz',
    },
    suspension_reason: {
      type: 'text',
    },
    last_login_at: {
      type: 'timestamptz',
    },
    created_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
    updated_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
    deleted_at: {
      type: 'timestamptz',
    },
  });

  pgm.createIndex({ schema: 'auth_svc', name: 'users' }, 'phone');
  pgm.createIndex({ schema: 'auth_svc', name: 'users' }, 'email');
  pgm.createIndex({ schema: 'auth_svc', name: 'users' }, 'role');

  // ----------------------------------------------------------
  // SESSIONS
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'auth_svc', name: 'sessions' }, {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('gen_random_uuid()'),
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: { schema: 'auth_svc', name: 'users' },
      onDelete: 'CASCADE',
    },
    device_id: {
      type: 'varchar(255)',
      notNull: true,
    },
    device_type: {
      type: 'varchar(50)',
      check: "device_type IN ('ANDROID','IOS','WEB')",
    },
    fcm_token: {
      type: 'text',
    },
    ip_address: {
      type: 'inet',
    },
    user_agent: {
      type: 'text',
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true,
    },
    expires_at: {
      type: 'timestamptz',
      notNull: true,
    },
    revoked_at: {
      type: 'timestamptz',
    },
    created_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
  });

  pgm.createIndex({ schema: 'auth_svc', name: 'sessions' }, 'user_id');
  pgm.createIndex({ schema: 'auth_svc', name: 'sessions' }, ['user_id', 'device_id']);
  pgm.createIndex({ schema: 'auth_svc', name: 'sessions' }, 'expires_at');

  // ----------------------------------------------------------
  // OTP ATTEMPTS
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'auth_svc', name: 'otp_attempts' }, {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('gen_random_uuid()'),
    },
    phone: {
      type: 'varchar(20)',
      notNull: true,
    },
    otp_hash: {
      type: 'varchar(255)',
      notNull: true,
    },
    attempt_count: {
      type: 'integer',
      notNull: true,
      default: 0,
    },
    verified_at: {
      type: 'timestamptz',
    },
    expires_at: {
      type: 'timestamptz',
      notNull: true,
    },
    created_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
  });

  pgm.createIndex({ schema: 'auth_svc', name: 'otp_attempts' }, 'phone');
  pgm.createIndex({ schema: 'auth_svc', name: 'otp_attempts' }, 'expires_at');

  // ----------------------------------------------------------
  // AUDIT LOGS (auth service's audit log)
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'auth_svc', name: 'audit_logs' }, {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('gen_random_uuid()'),
    },
    actor_id: {
      type: 'uuid',
    },
    actor_role: {
      type: 'varchar(50)',
    },
    action: {
      type: 'varchar(100)',
      notNull: true,
    },
    resource_type: {
      type: 'varchar(50)',
    },
    resource_id: {
      type: 'uuid',
    },
    changes: {
      type: 'jsonb',
    },
    ip_address: {
      type: 'inet',
    },
    user_agent: {
      type: 'text',
    },
    request_id: {
      type: 'varchar(36)',
    },
    created_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
  });

  pgm.createIndex({ schema: 'auth_svc', name: 'audit_logs' }, 'actor_id');
  pgm.createIndex({ schema: 'auth_svc', name: 'audit_logs' }, 'action');
  pgm.createIndex({ schema: 'auth_svc', name: 'audit_logs' }, 'created_at');

  // updated_at trigger function
  pgm.createFunction(
    'update_updated_at_column',
    [],
    {
      returns: 'trigger',
      language: 'plpgsql',
      replace: true,
    },
    `
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    `,
  );

  pgm.createTrigger(
    { schema: 'auth_svc', name: 'users' },
    'update_users_updated_at',
    {
      when: 'BEFORE',
      operation: 'UPDATE',
      function: 'update_updated_at_column',
      level: 'ROW',
    },
  );
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'auth_svc', name: 'audit_logs' });
  pgm.dropTable({ schema: 'auth_svc', name: 'otp_attempts' });
  pgm.dropTable({ schema: 'auth_svc', name: 'sessions' });
  pgm.dropTable({ schema: 'auth_svc', name: 'users' });
};
