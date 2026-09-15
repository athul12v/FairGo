/* eslint-disable */
// Migration: 008_support_schema

exports.up = (pgm) => {
  // ----------------------------------------------------------
  // SUPPORT CASES
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'support_cases' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    ticket_number: { type: 'varchar(32)', notNull: true, unique: true },
    user_id: { type: 'uuid', notNull: true },
    user_role: { type: 'varchar(20)', notNull: true, default: "'RIDER'" },
    trip_id: { type: 'uuid' },
    channel: {
      type: 'varchar(20)', notNull: true,
      check: "channel IN ('CALL', 'EMAIL', 'CHAT')",
    },
    category: {
      type: 'varchar(40)', notNull: true,
      check: "category IN ('TRIP_ISSUE', 'PAYMENT_ISSUE', 'DRIVER_BEHAVIOUR', 'LOST_ITEM', 'SAFETY', 'ACCOUNT', 'TECHNICAL', 'OTHER')",
    },
    subject: { type: 'varchar(255)', notNull: true },
    description: { type: 'text', notNull: true },
    status: {
      type: 'varchar(30)', notNull: true, default: "'OPEN'",
      check: "status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'WAITING_CUSTOMER', 'RESOLVED', 'CLOSED')",
    },
    priority: {
      type: 'varchar(20)', notNull: true, default: "'MEDIUM'",
      check: "priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')",
    },
    assigned_agent_id: { type: 'uuid' },
    internal_notes: { type: 'text' },
    attachments: { type: 'jsonb', notNull: true, default: "'[]'" },
    csat_rating: { type: 'smallint', check: 'csat_rating >= 1 AND csat_rating <= 5' },
    csat_comment: { type: 'text' },
    resolved_at: { type: 'timestamptz' },
    closed_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'support_cases' }, 'ticket_number');
  pgm.createIndex({ schema: 'support_svc', name: 'support_cases' }, 'user_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_cases' }, 'status');
  pgm.createIndex({ schema: 'support_svc', name: 'support_cases' }, 'assigned_agent_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_cases' }, 'created_at');

  // ----------------------------------------------------------
  // SUPPORT CONVERSATIONS (Live Chat sessions)
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'support_conversations' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    case_id: {
      type: 'uuid', notNull: true,
      references: { schema: 'support_svc', name: 'support_cases' },
      onDelete: 'CASCADE',
    },
    user_id: { type: 'uuid', notNull: true },
    agent_id: { type: 'uuid' },
    status: {
      type: 'varchar(20)', notNull: true, default: "'WAITING'",
      check: "status IN ('WAITING', 'ACTIVE', 'ENDED')",
    },
    webrtc_session_id: { type: 'varchar(128)' },
    started_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    ended_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'support_conversations' }, 'case_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_conversations' }, 'user_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_conversations' }, 'agent_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_conversations' }, 'status');

  // ----------------------------------------------------------
  // SUPPORT MESSAGES
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'support_messages' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    conversation_id: {
      type: 'uuid', notNull: true,
      references: { schema: 'support_svc', name: 'support_conversations' },
      onDelete: 'CASCADE',
    },
    sender_id: { type: 'uuid', notNull: true },
    sender_role: {
      type: 'varchar(20)', notNull: true,
      check: "sender_role IN ('CUSTOMER', 'AGENT', 'SYSTEM')",
    },
    type: {
      type: 'varchar(20)', notNull: true, default: "'TEXT'",
      check: "type IN ('TEXT', 'IMAGE', 'FILE', 'SYSTEM')",
    },
    content: { type: 'text', notNull: true },
    attachment_url: { type: 'text' },
    attachment_metadata: { type: 'jsonb' },
    delivery_status: {
      type: 'varchar(20)', notNull: true, default: "'SENT'",
      check: "delivery_status IN ('SENT', 'DELIVERED', 'READ')",
    },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'support_messages' }, 'conversation_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_messages' }, 'created_at');

  // ----------------------------------------------------------
  // CALLBACK REQUESTS
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'support_callback_requests' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    case_id: {
      type: 'uuid', notNull: true,
      references: { schema: 'support_svc', name: 'support_cases' },
      onDelete: 'CASCADE',
    },
    user_id: { type: 'uuid', notNull: true },
    phone_number: { type: 'varchar(20)', notNull: true },
    preferred_time_window: { type: 'varchar(64)', notNull: true },
    status: {
      type: 'varchar(20)', notNull: true, default: "'PENDING'",
      check: "status IN ('PENDING', 'SCHEDULED', 'COMPLETED', 'CANCELLED')",
    },
    assigned_agent_id: { type: 'uuid' },
    notes: { type: 'text' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'support_callback_requests' }, 'user_id');
  pgm.createIndex({ schema: 'support_svc', name: 'support_callback_requests' }, 'status');

  // ----------------------------------------------------------
  // FAQS & KNOWLEDGE ARTICLES (Context-first Google Support style)
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'support_faqs' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    category: { type: 'varchar(40)', notNull: true },
    question: { type: 'varchar(255)', notNull: true },
    answer: { type: 'text', notNull: true },
    sort_order: { type: 'smallint', notNull: true, default: 0 },
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'support_faqs' }, 'category');

  // ----------------------------------------------------------
  // OUTBOX (Transactional messaging)
  // ----------------------------------------------------------
  pgm.createTable({ schema: 'support_svc', name: 'outbox' }, {
    id: { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    event_id: { type: 'varchar(64)', notNull: true, unique: true },
    event_type: { type: 'varchar(128)', notNull: true },
    topic: { type: 'varchar(128)', notNull: true },
    payload: { type: 'jsonb', notNull: true },
    published: { type: 'boolean', notNull: true, default: false },
    published_at: { type: 'timestamptz' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex({ schema: 'support_svc', name: 'outbox' }, ['published', 'created_at']);
};

exports.down = (pgm) => {
  pgm.dropTable({ schema: 'support_svc', name: 'outbox' });
  pgm.dropTable({ schema: 'support_svc', name: 'support_faqs' });
  pgm.dropTable({ schema: 'support_svc', name: 'support_callback_requests' });
  pgm.dropTable({ schema: 'support_svc', name: 'support_messages' });
  pgm.dropTable({ schema: 'support_svc', name: 'support_conversations' });
  pgm.dropTable({ schema: 'support_svc', name: 'support_cases' });
};
