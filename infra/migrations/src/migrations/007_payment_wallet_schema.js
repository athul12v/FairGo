/* eslint-disable */
// Migration: 007_payment_wallet_schema

exports.up = (pgm) => {
  // ----------------------------------------------------------
  // PAYMENTS
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'payment_svc', name: 'payments' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    trip_id: { type: 'uuid' },
    parcel_id: { type: 'uuid' },
    rider_id: { type: 'uuid', notNull: true },
    amount_paise: { type: 'bigint', notNull: true, check: 'amount_paise > 0' },
    currency: { type: 'varchar(3)', notNull: true, default: "'INR'" },
    method: {
      type: 'varchar(20)', notNull: true,
      check: "method IN ('UPI','CREDIT_CARD','DEBIT_CARD','NET_BANKING','WALLET','CASH','CORPORATE')",
    },
    provider: {
      type: 'varchar(30)', notNull: true,
      check: "provider IN ('RAZORPAY','STRIPE','PAYU','CASH','INTERNAL_WALLET')",
    },
    provider_payment_id: { type: 'varchar(255)' },
    provider_order_id: { type: 'varchar(255)' },
    status: {
      type: 'varchar(30)', notNull: true, default: "'PENDING'",
      check: "status IN ('PENDING','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED','CANCELLED')",
    },
    idempotency_key: { type: 'varchar(255)', notNull: true, unique: true },
    refunded_amount_paise: { type: 'bigint', notNull: true, default: 0 },
    metadata: { type: 'jsonb', notNull: true, default: "'{}'" },
    authorized_at: { type: 'timestamptz' },
    captured_at: { type: 'timestamptz' },
    failed_at: { type: 'timestamptz' },
    failure_reason: { type: 'text' },
    webhook_data: { type: 'jsonb' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'payment_svc', name: 'payments' }, 'trip_id');
  pgm.createIndex({ schema: 'payment_svc', name: 'payments' }, 'rider_id');
  pgm.createIndex({ schema: 'payment_svc', name: 'payments' }, 'status');
  pgm.createIndex({ schema: 'payment_svc', name: 'payments' }, 'provider_payment_id');
  pgm.createIndex({ schema: 'payment_svc', name: 'payments' }, 'idempotency_key');

  // Refunds
  pgm.createTable({ schema: 'payment_svc', name: 'refunds' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    payment_id: { type: 'uuid', notNull: true, references: { schema: 'payment_svc', name: 'payments' } },
    amount_paise: { type: 'bigint', notNull: true, check: 'amount_paise > 0' },
    reason: { type: 'text', notNull: true },
    provider_refund_id: { type: 'varchar(255)' },
    status: {
      type: 'varchar(20)', notNull: true, default: "'PENDING'",
      check: "status IN ('PENDING','PROCESSING','COMPLETED','FAILED')",
    },
    idempotency_key: { type: 'varchar(255)', notNull: true, unique: true },
    processed_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'payment_svc', name: 'refunds' }, 'payment_id');

  // Outbox
  pgm.createTable({ schema: 'payment_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_type: { type: 'varchar(100)', notNull: true },
    topic: { type: 'varchar(200)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    correlation_id: { type: 'uuid', notNull: true },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'payment_svc', name: 'outbox' }, 'published_at');

  pgm.createTrigger({ schema: 'payment_svc', name: 'payments' }, 'update_payments_updated_at', {
    when: 'BEFORE', operation: 'UPDATE', function: 'update_updated_at_column', level: 'ROW',
  });

  // ----------------------------------------------------------
  // WALLETS & LEDGER
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'wallet_svc', name: 'wallet_accounts' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    owner_id: { type: 'uuid', notNull: true },
    wallet_type: {
      type: 'varchar(30)', notNull: true,
      check: "wallet_type IN ('RIDER','DRIVER','PLATFORM_REVENUE','PLATFORM_INCENTIVES','TRIP_ESCROW','CASHBACK_POOL')",
    },
    currency: { type: 'varchar(3)', notNull: true, default: "'INR'" },
    is_locked: { type: 'boolean', notNull: true, default: false },
    kyc_tier: {
      type: 'varchar(10)', notNull: true, default: "'NONE'",
      check: "kyc_tier IN ('NONE','MIN','FULL')",
    },
    // RBI PPI limits (paise): NONE=0, MIN=10000_00, FULL=200000_00
    monthly_load_limit_paise: { type: 'bigint', notNull: true, default: 0 },
    monthly_loaded_paise: { type: 'bigint', notNull: true, default: 0 },
    monthly_limit_reset_date: { type: 'date' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.addConstraint({ schema: 'wallet_svc', name: 'wallet_accounts' }, 'uq_wallet_owner_type', 'UNIQUE (owner_id, wallet_type)');
  pgm.createIndex({ schema: 'wallet_svc', name: 'wallet_accounts' }, 'owner_id');

  // Double-entry immutable ledger
  pgm.createTable({ schema: 'wallet_svc', name: 'ledger_entries' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    wallet_id: { type: 'uuid', notNull: true, references: { schema: 'wallet_svc', name: 'wallet_accounts' } },
    entry_type: {
      type: 'varchar(10)', notNull: true,
      check: "entry_type IN ('DEBIT','CREDIT')",
    },
    amount_paise: { type: 'bigint', notNull: true, check: 'amount_paise > 0' },
    balance_after_paise: { type: 'bigint', notNull: true },
    reference_type: { type: 'varchar(50)', notNull: true }, // TRIP, TOPUP, REFUND, CASHBACK, PAYOUT, etc.
    reference_id: { type: 'uuid', notNull: true },
    description: { type: 'text', notNull: true },
    idempotency_key: { type: 'varchar(255)', notNull: true, unique: true },
    // Immutable: no updated_at, no deleted_at
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'wallet_svc', name: 'ledger_entries' }, ['wallet_id', 'created_at']);
  pgm.createIndex({ schema: 'wallet_svc', name: 'ledger_entries' }, 'reference_id');
  pgm.createIndex({ schema: 'wallet_svc', name: 'ledger_entries' }, 'idempotency_key');

  // Payouts
  pgm.createTable({ schema: 'wallet_svc', name: 'payouts' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    driver_id: { type: 'uuid', notNull: true },
    wallet_id: { type: 'uuid', notNull: true, references: { schema: 'wallet_svc', name: 'wallet_accounts' } },
    amount_paise: { type: 'bigint', notNull: true, check: 'amount_paise > 0' },
    status: {
      type: 'varchar(20)', notNull: true, default: "'PENDING'",
      check: "status IN ('PENDING','PROCESSING','COMPLETED','FAILED','CANCELLED')",
    },
    provider: { type: 'varchar(30)', notNull: true },
    provider_payout_id: { type: 'varchar(255)' },
    bank_account_last4: { type: 'varchar(4)' },
    idempotency_key: { type: 'varchar(255)', notNull: true, unique: true },
    failure_reason: { type: 'text' },
    initiated_at: { type: 'timestamptz' },
    completed_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'wallet_svc', name: 'payouts' }, 'driver_id');
  pgm.createIndex({ schema: 'wallet_svc', name: 'payouts' }, 'status');

  // Materialized view: current wallet balances (refreshed on each ledger write via trigger)
  pgm.sql(`
    CREATE MATERIALIZED VIEW wallet_svc.wallet_balances AS
    SELECT
      wallet_id,
      COALESCE(
        SUM(CASE WHEN entry_type = 'CREDIT' THEN amount_paise ELSE -amount_paise END),
        0
      ) AS balance_paise
    FROM wallet_svc.ledger_entries
    GROUP BY wallet_id;
  `);
  pgm.sql('CREATE UNIQUE INDEX ON wallet_svc.wallet_balances (wallet_id)');

  // Wallet outbox
  pgm.createTable({ schema: 'wallet_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_type: { type: 'varchar(100)', notNull: true },
    topic: { type: 'varchar(200)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    correlation_id: { type: 'uuid', notNull: true },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex({ schema: 'wallet_svc', name: 'outbox' }, 'published_at');
};

exports.down = (pgm) => {
  pgm.sql('DROP MATERIALIZED VIEW IF EXISTS wallet_svc.wallet_balances');
  pgm.dropTable({ schema: 'wallet_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'wallet_svc', name: 'payouts' });
  pgm.dropTable({ schema: 'wallet_svc', name: 'ledger_entries' });
  pgm.dropTable({ schema: 'wallet_svc', name: 'wallet_accounts' });
  pgm.dropTable({ schema: 'payment_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'payment_svc', name: 'refunds' });
  pgm.dropTable({ schema: 'payment_svc', name: 'payments' });
};
