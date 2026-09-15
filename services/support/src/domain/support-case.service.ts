// services/support/src/domain/support-case.service.ts

import { getDb, getRedis } from '../infrastructure/database.js';
import {
  SupportChannel,
  SupportPriority,
  SupportTicketCategory,
  SupportTicketStatus,
  type SupportCase,
  type SupportAvailability,
  type SupportFaqItem,
  type SupportCallbackRequest,
  type UUID,
} from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';

const log = createLogger('support-case-service');

interface CaseDbRow {
  id: string;
  ticket_number: string;
  user_id: string;
  user_role: 'RIDER' | 'DRIVER';
  trip_id: string | null;
  channel: SupportChannel;
  category: SupportTicketCategory;
  subject: string;
  description: string;
  status: SupportTicketStatus;
  priority: SupportPriority;
  assigned_agent_id: string | null;
  internal_notes: string | null;
  attachments: Array<{ url: string; fileName: string; fileSize: number; mimeType: string }>;
  resolved_at: Date | null;
  closed_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

interface CallbackDbRow {
  id: string;
  case_id: string;
  user_id: string;
  phone_number: string;
  preferred_time_window: string;
  status: 'PENDING' | 'SCHEDULED' | 'COMPLETED' | 'CANCELLED';
  assigned_agent_id: string | null;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

export class SupportCaseService {
  /**
   * Generates human-readable ticket number: FG-2026-XXXXX
   */
  private static generateTicketNumber(): string {
    const randomNum = Math.floor(10000 + Math.random() * 90000);
    const year = new Date().getFullYear();
    return `FG-${year}-${randomNum}`;
  }

  /**
   * Calculates actual live availability for Chat, Call, and Email
   */
  async getAvailability(): Promise<SupportAvailability> {
    const redis = await getRedis();
    const onlineAgentsCount = await redis.sCard('support:agents:online');
    const queueLength = await redis.zCard('support:chat:waiting_queue');

    // Estimated wait time in seconds (approx 90s per customer in queue per agent)
    const activeAgents = Math.max(onlineAgentsCount, 1);
    const estimatedWaitSeconds =
      onlineAgentsCount > 0 ? Math.round((queueLength * 90) / activeAgents) : 0;

    return {
      chat: {
        isAvailable: onlineAgentsCount > 0,
        activeAgentsCount: onlineAgentsCount,
        queueLength,
        estimatedWaitSeconds,
      },
      call: {
        isAvailable: true,
        phoneNumber: '+91 1800 419 2244',
        operatingHours: '24/7 Priority Support',
        callbackAvailable: true,
      },
      email: {
        isAvailable: true,
        responseTimeWindow: 'Within 4-8 hours',
      },
    };
  }

  /**
   * Returns categorized FAQs for instant self-help (Google Support philosophy)
   */
  async getFaqs(category?: SupportTicketCategory): Promise<SupportFaqItem[]> {
    const defaultFaqs: SupportFaqItem[] = [
      {
        id: 'faq-1',
        category: SupportTicketCategory.TRIP_ISSUE,
        question: 'How do I report an item left behind in a vehicle?',
        answer:
          'Select the trip from your Trip History and tap "Lost Item". You can call the driver directly for up to 48 hours with number masking, or contact FairGo 24/7 support to assist.',
        sortOrder: 1,
        isActive: true,
      },
      {
        id: 'faq-2',
        category: SupportTicketCategory.PAYMENT_ISSUE,
        question: 'Why was I charged a cancellation fee or surge fare?',
        answer:
          'FairGo enforces 100% surge cap transparency. Cancellation fees only apply if cancelled more than 3 minutes after a driver was dispatched. If you were incorrectly charged, we issue an instant wallet refund.',
        sortOrder: 2,
        isActive: true,
      },
      {
        id: 'faq-3',
        category: SupportTicketCategory.ACCOUNT,
        question: 'How do I update my mobile number or email address?',
        answer:
          'Go to Profile > Edit Profile. Changing your mobile number requires an OTP verification sent to both your old and new number for account security.',
        sortOrder: 3,
        isActive: true,
      },
      {
        id: 'faq-4',
        category: SupportTicketCategory.SAFETY,
        question: 'What safety features does FairGo have during rides?',
        answer:
          'Every FairGo trip has 24/7 GPS tracking, live trip sharing with emergency contacts, dedicated in-app SOS with local police integration, and verified drivers.',
        sortOrder: 4,
        isActive: true,
      },
      {
        id: 'faq-5',
        category: SupportTicketCategory.TECHNICAL,
        question: 'The app is having trouble detecting my pickup location',
        answer:
          'Ensure Location permissions are set to "While using the app" and High Accuracy is enabled. You can also manually adjust the pin on the map.',
        sortOrder: 5,
        isActive: true,
      },
    ];

    if (category) {
      return defaultFaqs.filter((f) => f.category === category);
    }
    return defaultFaqs;
  }

  /**
   * Create an email support case
   */
  async createEmailCase(params: {
    userId: UUID;
    userRole: 'RIDER' | 'DRIVER';
    tripId?: UUID;
    category: SupportTicketCategory;
    subject: string;
    description: string;
    attachments?: Array<{ url: string; fileName: string; fileSize: number; mimeType: string }>;
  }): Promise<SupportCase> {
    const db = getDb();
    const ticketNumber = SupportCaseService.generateTicketNumber();

    const result = await db.query<CaseDbRow>(
      `INSERT INTO support_svc.support_cases (
        ticket_number, user_id, user_role, trip_id, channel,
        category, subject, description, status, priority, attachments
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [
        ticketNumber,
        params.userId,
        params.userRole,
        params.tripId ?? null,
        SupportChannel.EMAIL,
        params.category,
        params.subject,
        params.description,
        SupportTicketStatus.OPEN,
        SupportPriority.MEDIUM,
        JSON.stringify(params.attachments ?? []),
      ]
    );

    const row = result.rows[0];
    if (!row) throw new Error('Failed to insert support case');
    log.info('Email support case created', { ticketNumber, userId: params.userId });

    return {
      id: row.id,
      ticketNumber: row.ticket_number,
      userId: row.user_id,
      userRole: row.user_role,
      tripId: row.trip_id ?? undefined,
      channel: row.channel,
      category: row.category,
      subject: row.subject,
      description: row.description,
      status: row.status,
      priority: row.priority,
      assignedAgentId: row.assigned_agent_id ?? undefined,
      internalNotes: row.internal_notes ?? undefined,
      attachments: row.attachments ?? [],
      createdAt: row.created_at.toISOString(),
      updatedAt: row.updated_at.toISOString(),
    };
  }

  /**
   * Request a callback
   */
  async requestCallback(params: {
    userId: UUID;
    userRole: 'RIDER' | 'DRIVER';
    phoneNumber: string;
    preferredTimeWindow: string;
    category: SupportTicketCategory;
    issueSummary: string;
    tripId?: UUID;
  }): Promise<{ case: SupportCase; callbackRequest: SupportCallbackRequest }> {
    const db = getDb();
    const ticketNumber = SupportCaseService.generateTicketNumber();

    const client = await db.connect();
    try {
      await client.query('BEGIN');

      const caseRes = await client.query<CaseDbRow>(
        `INSERT INTO support_svc.support_cases (
          ticket_number, user_id, user_role, trip_id, channel,
          category, subject, description, status, priority
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *`,
        [
          ticketNumber,
          params.userId,
          params.userRole,
          params.tripId ?? null,
          SupportChannel.CALL,
          params.category,
          `Callback Request: ${params.issueSummary.slice(0, 50)}`,
          params.issueSummary,
          SupportTicketStatus.OPEN,
          SupportPriority.HIGH,
        ]
      );
      const caseRow = caseRes.rows[0];
      if (!caseRow) throw new Error('Failed to create callback case');

      const cbRes = await client.query<CallbackDbRow>(
        `INSERT INTO support_svc.support_callback_requests (
          case_id, user_id, phone_number, preferred_time_window, status, notes
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *`,
        [
          caseRow.id,
          params.userId,
          params.phoneNumber,
          params.preferredTimeWindow,
          'PENDING',
          params.issueSummary,
        ]
      );
      const cbRow = cbRes.rows[0];
      if (!cbRow) throw new Error('Failed to create callback request record');

      await client.query('COMMIT');
      log.info('Callback requested', { ticketNumber, userId: params.userId });

      const supportCase: SupportCase = {
        id: caseRow.id,
        ticketNumber: caseRow.ticket_number,
        userId: caseRow.user_id,
        userRole: caseRow.user_role,
        tripId: caseRow.trip_id ?? undefined,
        channel: caseRow.channel,
        category: caseRow.category,
        subject: caseRow.subject,
        description: caseRow.description,
        status: caseRow.status,
        priority: caseRow.priority,
        attachments: [],
        createdAt: caseRow.created_at.toISOString(),
        updatedAt: caseRow.updated_at.toISOString(),
      };

      const callbackRequest: SupportCallbackRequest = {
        id: cbRow.id,
        caseId: cbRow.case_id,
        userId: cbRow.user_id,
        phoneNumber: cbRow.phone_number,
        preferredTimeWindow: cbRow.preferred_time_window,
        status: cbRow.status,
        notes: cbRow.notes ?? undefined,
        createdAt: cbRow.created_at.toISOString(),
        updatedAt: cbRow.updated_at.toISOString(),
      };

      return { case: supportCase, callbackRequest };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Get cases for a customer
   */
  async getUserCases(userId: UUID): Promise<SupportCase[]> {
    const db = getDb();
    const res = await db.query<CaseDbRow>(
      `SELECT * FROM support_svc.support_cases
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 50`,
      [userId]
    );

    return res.rows.map((row: CaseDbRow) => ({
      id: row.id,
      ticketNumber: row.ticket_number,
      userId: row.user_id,
      userRole: row.user_role,
      tripId: row.trip_id ?? undefined,
      channel: row.channel,
      category: row.category,
      subject: row.subject,
      description: row.description,
      status: row.status,
      priority: row.priority,
      assignedAgentId: row.assigned_agent_id ?? undefined,
      attachments: row.attachments ?? [],
      resolvedAt: row.resolved_at?.toISOString(),
      closedAt: row.closed_at?.toISOString(),
      createdAt: row.created_at.toISOString(),
      updatedAt: row.updated_at.toISOString(),
    }));
  }

  /**
   * Add internal agent note
   */
  async addInternalNote(caseId: UUID, agentId: UUID, note: string): Promise<void> {
    const db = getDb();
    await db.query(
      `UPDATE support_svc.support_cases
       SET internal_notes = CONCAT(COALESCE(internal_notes, ''), '\n[', NOW()::text, ' by agent ', $2::text, ']: ', $3::text),
           updated_at = NOW()
       WHERE id = $1`,
      [caseId, agentId, note]
    );
  }

  /**
   * Update case status
   */
  async updateCaseStatus(caseId: UUID, status: SupportTicketStatus): Promise<void> {
    const db = getDb();
    const resolvedAt = status === SupportTicketStatus.RESOLVED ? 'NOW()' : 'resolved_at';
    const closedAt = status === SupportTicketStatus.CLOSED ? 'NOW()' : 'closed_at';

    await db.query(
      `UPDATE support_svc.support_cases
       SET status = $2,
           resolved_at = ${resolvedAt},
           closed_at = ${closedAt},
           updated_at = NOW()
       WHERE id = $1`,
      [caseId, status]
    );
  }
}
