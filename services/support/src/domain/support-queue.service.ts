// services/support/src/domain/support-queue.service.ts

import { getDb, getRedis } from '../infrastructure/database.js';
import {
  SupportChannel,
  SupportPriority,
  SupportTicketCategory,
  SupportTicketStatus,
  ConversationStatus,
  MessageType,
  SenderRole,
  DeliveryStatus,
  type SupportCase,
  type SupportConversation,
  type SupportMessage,
  type UUID,
} from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';

const log = createLogger('support-queue-service');

interface CaseRow {
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
  created_at: Date;
  updated_at: Date;
}

interface ConversationRow {
  id: string;
  case_id: string;
  user_id: string;
  agent_id: string | null;
  status: ConversationStatus;
  webrtc_session_id: string | null;
  started_at: Date;
  ended_at: Date | null;
  created_at: Date;
}

interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string;
  sender_role: SenderRole;
  type: MessageType;
  content: string;
  attachment_url: string | null;
  attachment_metadata: Record<string, unknown> | null;
  delivery_status: DeliveryStatus;
  created_at: Date;
}

interface QueueQueryRow {
  conversation_id: string;
  case_id: string;
  ticket_number: string;
  user_id: string;
  category: SupportTicketCategory;
  subject: string;
  started_at: Date;
  wait_seconds: number;
}

export interface QueueItem {
  readonly conversationId: UUID;
  readonly caseId: UUID;
  readonly ticketNumber: string;
  readonly userId: UUID;
  readonly category: SupportTicketCategory;
  readonly subject: string;
  readonly queuedAt: string;
  readonly waitSeconds: number;
}

export class SupportQueueService {
  /**
   * Agent marks themselves online
   */
  async setAgentOnline(agentId: UUID, agentName: string): Promise<void> {
    const redis = await getRedis();
    await redis.sAdd('support:agents:online', agentId);
    await redis.hSet(`support:agent:${agentId}`, {
      name: agentName,
      status: 'ONLINE',
      lastSeen: new Date().toISOString(),
    });
    log.info('Support agent online', { agentId });
  }

  /**
   * Agent marks themselves offline
   */
  async setAgentOffline(agentId: UUID): Promise<void> {
    const redis = await getRedis();
    await redis.sRem('support:agents:online', agentId);
    await redis.hSet(`support:agent:${agentId}`, 'status', 'OFFLINE');
    log.info('Support agent offline', { agentId });
  }

  /**
   * Customer initiates a live support chat:
   * 1. Creates SupportCase in 'OPEN' status
   * 2. Creates SupportConversation in 'WAITING' status
   * 3. Adds to Redis priority queue sorted by timestamp
   */
  async enqueueCustomerForChat(params: {
    userId: UUID;
    userRole: 'RIDER' | 'DRIVER';
    category: SupportTicketCategory;
    subject: string;
    description: string;
    tripId?: UUID;
  }): Promise<{ case: SupportCase; conversation: SupportConversation; queuePosition: number }> {
    const db = getDb();
    const redis = await getRedis();
    const ticketNumber = `FG-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;

    const client = await db.connect();
    try {
      await client.query('BEGIN');

      // 1. Create Case
      const caseRes = await client.query<CaseRow>(
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
          SupportChannel.CHAT,
          params.category,
          params.subject,
          params.description,
          SupportTicketStatus.OPEN,
          SupportPriority.HIGH,
        ]
      );
      const caseRow = caseRes.rows[0];
      if (!caseRow) throw new Error('Failed to create support case');

      // 2. Create Conversation
      const convRes = await client.query<ConversationRow>(
        `INSERT INTO support_svc.support_conversations (
          case_id, user_id, status
        ) VALUES ($1, $2, $3)
        RETURNING *`,
        [caseRow.id, params.userId, ConversationStatus.WAITING]
      );
      const convRow = convRes.rows[0];
      if (!convRow) throw new Error('Failed to create support conversation');

      // Initial system welcome message
      await client.query(
        `INSERT INTO support_svc.support_messages (
          conversation_id, sender_id, sender_role, type, content, delivery_status
        ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          convRow.id,
          '00000000-0000-0000-0000-000000000000',
          SenderRole.SYSTEM,
          MessageType.SYSTEM,
          `Connecting you to a support specialist for case #${ticketNumber}. We're here to help!`,
          DeliveryStatus.DELIVERED,
        ]
      );

      await client.query('COMMIT');

      // 3. Add to Redis Waiting Queue (score = timestamp in epoch ms)
      const now = Date.now();
      await redis.zAdd('support:chat:waiting_queue', {
        score: now,
        value: convRow.id,
      });

      // Get customer queue position (0-indexed -> 1-indexed)
      const rank = await redis.zRank('support:chat:waiting_queue', convRow.id);
      const queuePosition = (rank ?? 0) + 1;

      log.info('Customer enqueued for support chat', {
        conversationId: convRow.id,
        ticketNumber,
      });

      return {
        case: {
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
        },
        conversation: {
          id: convRow.id,
          caseId: convRow.case_id,
          userId: convRow.user_id,
          status: convRow.status,
          startedAt: convRow.started_at.toISOString(),
          createdAt: convRow.created_at.toISOString(),
        },
        queuePosition,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Agent accepts a waiting conversation
   */
  async acceptConversation(
    agentId: UUID,
    agentName: string,
    conversationId: UUID
  ): Promise<SupportConversation> {
    const db = getDb();
    const redis = await getRedis();

    // Remove from queue
    await redis.zRem('support:chat:waiting_queue', conversationId);

    // Update conversation in DB
    const res = await db.query<ConversationRow>(
      `UPDATE support_svc.support_conversations
       SET agent_id = $1,
           status = $2
       WHERE id = $3
       RETURNING *`,
      [agentId, ConversationStatus.ACTIVE, conversationId]
    );

    const row = res.rows[0];
    if (!row) {
      throw new Error(`Conversation not found: ${conversationId}`);
    }

    // Update case to ASSIGNED & IN_PROGRESS
    await db.query(
      `UPDATE support_svc.support_cases
       SET assigned_agent_id = $1,
           status = $2,
           updated_at = NOW()
       WHERE id = $3`,
      [agentId, SupportTicketStatus.IN_PROGRESS, row.case_id]
    );

    // Insert system message into conversation
    await db.query(
      `INSERT INTO support_svc.support_messages (
        conversation_id, sender_id, sender_role, type, content, delivery_status
      ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        conversationId,
        agentId,
        SenderRole.SYSTEM,
        MessageType.SYSTEM,
        `${agentName} has joined the conversation.`,
        DeliveryStatus.DELIVERED,
      ]
    );

    log.info('Conversation accepted by agent', { conversationId, agentId });

    return {
      id: row.id,
      caseId: row.case_id,
      userId: row.user_id,
      agentId: row.agent_id ?? undefined,
      agentName,
      status: row.status,
      webrtcSessionId: row.webrtc_session_id ?? undefined,
      startedAt: row.started_at.toISOString(),
      createdAt: row.created_at.toISOString(),
    };
  }

  /**
   * Record message into conversation
   */
  async saveMessage(params: {
    conversationId: UUID;
    senderId: UUID;
    senderRole: SenderRole;
    type: MessageType;
    content: string;
    attachmentUrl?: string | undefined;
    attachmentMetadata?: Record<string, unknown> | undefined;
  }): Promise<SupportMessage> {
    const db = getDb();
    const res = await db.query<MessageRow>(
      `INSERT INTO support_svc.support_messages (
        conversation_id, sender_id, sender_role, type, content, attachment_url, attachment_metadata, delivery_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        params.conversationId,
        params.senderId,
        params.senderRole,
        params.type,
        params.content,
        params.attachmentUrl ?? null,
        params.attachmentMetadata ? JSON.stringify(params.attachmentMetadata) : null,
        DeliveryStatus.SENT,
      ]
    );

    const row = res.rows[0];
    if (!row) throw new Error('Failed to save support message');

    return {
      id: row.id,
      conversationId: row.conversation_id,
      senderId: row.sender_id,
      senderRole: row.sender_role,
      type: row.type,
      content: row.content,
      attachmentUrl: row.attachment_url ?? undefined,
      attachmentMetadata: row.attachment_metadata ?? undefined,
      deliveryStatus: row.delivery_status,
      createdAt: row.created_at.toISOString(),
    };
  }

  /**
   * Fetch conversation history
   */
  async getMessages(conversationId: UUID): Promise<SupportMessage[]> {
    const db = getDb();
    const res = await db.query<MessageRow>(
      `SELECT * FROM support_svc.support_messages
       WHERE conversation_id = $1
       ORDER BY created_at ASC`,
      [conversationId]
    );

    return res.rows.map((row: MessageRow) => ({
      id: row.id,
      conversationId: row.conversation_id,
      senderId: row.sender_id,
      senderRole: row.sender_role,
      type: row.type,
      content: row.content,
      attachmentUrl: row.attachment_url ?? undefined,
      attachmentMetadata: row.attachment_metadata ?? undefined,
      deliveryStatus: row.delivery_status,
      createdAt: row.created_at.toISOString(),
    }));
  }

  /**
   * End support conversation
   */
  async endConversation(conversationId: UUID, endedByRole: 'CUSTOMER' | 'AGENT'): Promise<void> {
    const db = getDb();
    const redis = await getRedis();
    await redis.zRem('support:chat:waiting_queue', conversationId);

    const res = await db.query<{ case_id: string }>(
      `UPDATE support_svc.support_conversations
       SET status = $1,
           ended_at = NOW()
       WHERE id = $2
       RETURNING case_id`,
      [ConversationStatus.ENDED, conversationId]
    );

    if (res.rows.length > 0) {
      const caseId = res.rows[0]!.case_id;
      // Mark case as resolved if ended by agent
      const newStatus =
        endedByRole === 'AGENT' ? SupportTicketStatus.RESOLVED : SupportTicketStatus.WAITING_CUSTOMER;
      await db.query(
        `UPDATE support_svc.support_cases
         SET status = $1,
             updated_at = NOW()
         WHERE id = $2`,
        [newStatus, caseId]
      );

      // System message
      await db.query(
        `INSERT INTO support_svc.support_messages (
          conversation_id, sender_id, sender_role, type, content, delivery_status
        ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          conversationId,
          '00000000-0000-0000-0000-000000000000',
          SenderRole.SYSTEM,
          MessageType.SYSTEM,
          `This support conversation has ended.`,
          DeliveryStatus.DELIVERED,
        ]
      );
    }
    log.info('Conversation ended', { conversationId });
  }

  /**
   * Submit Customer CSAT Rating
   */
  async submitCsat(caseId: UUID, rating: number, comment?: string): Promise<void> {
    const db = getDb();
    await db.query(
      `UPDATE support_svc.support_cases
       SET csat_rating = $1,
           csat_comment = $2,
           status = $3,
           closed_at = NOW(),
           updated_at = NOW()
       WHERE id = $4`,
      [rating, comment ?? null, SupportTicketStatus.CLOSED, caseId]
    );
    log.info('CSAT submitted for case', { caseId });
  }

  /**
   * Agent Dashboard: Get waiting queue
   */
  async getWaitingQueue(): Promise<QueueItem[]> {
    const db = getDb();
    const res = await db.query<QueueQueryRow>(
      `SELECT
        c.id as conversation_id,
        c.case_id,
        sc.ticket_number,
        c.user_id,
        sc.category,
        sc.subject,
        c.started_at,
        EXTRACT(EPOCH FROM (NOW() - c.started_at))::int as wait_seconds
       FROM support_svc.support_conversations c
       JOIN support_svc.support_cases sc ON sc.id = c.case_id
       WHERE c.status = 'WAITING'
       ORDER BY c.started_at ASC`
    );

    return res.rows.map((r: QueueQueryRow) => ({
      conversationId: r.conversation_id,
      caseId: r.case_id,
      ticketNumber: r.ticket_number,
      userId: r.user_id,
      category: r.category,
      subject: r.subject,
      queuedAt: r.started_at.toISOString(),
      waitSeconds: r.wait_seconds,
    }));
  }

  /**
   * Agent Dashboard: Get active conversations
   */
  async getActiveConversations(agentId: UUID): Promise<SupportConversation[]> {
    const db = getDb();
    const res = await db.query<ConversationRow>(
      `SELECT * FROM support_svc.support_conversations
       WHERE agent_id = $1 AND status = 'ACTIVE'
       ORDER BY started_at DESC`,
      [agentId]
    );

    return res.rows.map((row: ConversationRow) => ({
      id: row.id,
      caseId: row.case_id,
      userId: row.user_id,
      agentId: row.agent_id ?? undefined,
      status: row.status,
      webrtcSessionId: row.webrtc_session_id ?? undefined,
      startedAt: row.started_at.toISOString(),
      createdAt: row.created_at.toISOString(),
    }));
  }
}
