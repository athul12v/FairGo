import { SupportCaseService } from '../../domain/support-case.service.js';
import { SupportQueueService } from '../../domain/support-queue.service.js';
import {
  SupportChannel,
  SupportPriority,
  SupportTicketCategory,
  SupportTicketStatus,
  ConversationStatus,
  MessageType,
  SenderRole,
  DeliveryStatus,
} from '@fairgo/shared-types';

// Mock DB and Redis infrastructure
const mockDbQuery = jest.fn() as any;
const mockClient = {
  query: mockDbQuery,
  release: jest.fn(),
};

const mockDbPool = {
  query: mockDbQuery,
  connect: jest.fn(async () => mockClient) as any,
};

const mockRedisStore: Record<string, any> = {};
const mockRedis = {
  sAdd: jest.fn(async (key: string, member: string) => {
    if (!mockRedisStore[key]) mockRedisStore[key] = new Set();
    mockRedisStore[key].add(member);
    return 1;
  }),
  sRem: jest.fn(async (key: string, member: string) => {
    if (mockRedisStore[key]) mockRedisStore[key].delete(member);
    return 1;
  }),
  sCard: jest.fn(async (key: string) => {
    return (mockRedisStore[key] ? mockRedisStore[key].size : 0);
  }),
  hSet: jest.fn(async (key: string, fieldOrObj: any, val?: any) => {
    if (typeof fieldOrObj === 'object') {
      mockRedisStore[key] = { ...(mockRedisStore[key] || {}), ...fieldOrObj };
    } else {
      if (!mockRedisStore[key]) mockRedisStore[key] = {};
      mockRedisStore[key][fieldOrObj] = val;
    }
    return 1;
  }),
  hGetAll: jest.fn(async (key: string) => {
    return mockRedisStore[key] || {};
  }),
  zAdd: jest.fn(async (key: string, item: { member: string; score: number }) => {
    if (!mockRedisStore[key]) mockRedisStore[key] = [];
    mockRedisStore[key].push(item);
    return 1;
  }),
  zRem: jest.fn(async (key: string, member: string) => {
    if (mockRedisStore[key]) {
      mockRedisStore[key] = mockRedisStore[key].filter((i: any) => i.member !== member);
    }
    return 1;
  }),
  zCard: jest.fn(async (key: string) => {
    return (mockRedisStore[key] ? mockRedisStore[key].length : 0);
  }),
  zRange: jest.fn(async (key: string, _start: number, _stop: number) => {
    return (mockRedisStore[key] || []).map((i: any) => i.member);
  }),
  zRank: jest.fn(async (key: string, member: string) => {
    const list = (mockRedisStore[key] || []).map((i: any) => i.member);
    const idx = list.indexOf(member);
    return idx === -1 ? null : idx;
  }),
};

jest.mock('../../infrastructure/database.js', () => ({
  getDb: () => mockDbPool,
  getRedis: async () => mockRedis,
}));

describe('Support Domain Services Unit Tests', () => {
  let caseService: SupportCaseService;
  let queueService: SupportQueueService;

  beforeEach(() => {
    jest.clearAllMocks();
    for (const key in mockRedisStore) {
      delete mockRedisStore[key];
    }
    caseService = new SupportCaseService();
    queueService = new SupportQueueService();
  });

  describe('SupportCaseService', () => {
    it('returns default categorized FAQs matching user inquiry', async () => {
      const allFaqs = await caseService.getFaqs();
      expect(allFaqs.length).toBeGreaterThanOrEqual(4);

      const tripFaqs = await caseService.getFaqs(SupportTicketCategory.TRIP_ISSUE);
      expect(tripFaqs.length).toBe(1);
      expect(tripFaqs[0]?.question).toContain('left behind');
    });

    it('creates an email support case and creates outbox event for async processing', async () => {
      const now = new Date();
      const mockCaseRow = {
        id: '11111111-1111-1111-1111-111111111111',
        ticket_number: 'FG-2026-10482',
        user_id: '22222222-2222-2222-2222-222222222222',
        user_role: 'RIDER',
        trip_id: null,
        channel: SupportChannel.EMAIL,
        category: SupportTicketCategory.PAYMENT_ISSUE,
        subject: 'Double charge dispute',
        description: 'Charged twice on UPI',
        status: SupportTicketStatus.OPEN,
        priority: SupportPriority.MEDIUM,
        assigned_agent_id: null,
        internal_notes: null,
        attachments: [],
        resolved_at: null,
        closed_at: null,
        created_at: now,
        updated_at: now,
      };

      mockDbQuery.mockResolvedValueOnce({ rows: [mockCaseRow] });

      const created = await caseService.createEmailCase({
        userId: '22222222-2222-2222-2222-222222222222',
        userRole: 'RIDER',
        category: SupportTicketCategory.PAYMENT_ISSUE,
        subject: 'Double charge dispute',
        description: 'Charged twice on UPI',
      });

      expect(created.ticketNumber).toBe('FG-2026-10482');
      expect(created.channel).toBe(SupportChannel.EMAIL);
      expect(created.status).toBe(SupportTicketStatus.OPEN);
      expect(mockDbQuery).toHaveBeenCalledTimes(1);
    });

    it('schedules a customer callback and records preference window', async () => {
      const now = new Date();
      const mockCaseRow = {
        id: 'case-1',
        ticket_number: 'FG-2026-88888',
        user_id: '22222222-2222-2222-2222-222222222222',
        user_role: 'RIDER',
        trip_id: null,
        channel: SupportChannel.CALL,
        category: SupportTicketCategory.PAYMENT_ISSUE,
        subject: 'Callback requested',
        description: 'Need assistance with payment receipt',
        status: SupportTicketStatus.OPEN,
        priority: SupportPriority.MEDIUM,
        assigned_agent_id: null,
        internal_notes: null,
        attachments: [],
        resolved_at: null,
        closed_at: null,
        created_at: now,
        updated_at: now,
      };

      const mockCallbackRow = {
        id: 'cb-1',
        case_id: 'case-1',
        user_id: '22222222-2222-2222-2222-222222222222',
        phone_number: '+919876543210',
        preferred_time_window: 'As soon as possible (10-15 mins)',
        status: 'PENDING',
        assigned_agent_id: null,
        notes: null,
        created_at: now,
        updated_at: now,
      };

      mockDbQuery
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ rows: [mockCaseRow] }) // insert case
        .mockResolvedValueOnce({ rows: [mockCallbackRow] }) // insert callback
        .mockResolvedValueOnce({ rows: [] }); // COMMIT

      const cb = await caseService.requestCallback({
        userId: '22222222-2222-2222-2222-222222222222',
        userRole: 'RIDER',
        phoneNumber: '+919876543210',
        preferredTimeWindow: 'As soon as possible (10-15 mins)',
        category: SupportTicketCategory.PAYMENT_ISSUE,
        issueSummary: 'Need assistance with payment receipt',
      });

      expect(cb.callbackRequest.id).toBe('cb-1');
      expect(cb.callbackRequest.phoneNumber).toBe('+919876543210');
    });

    it('accurately reports chat availability when agents are online vs offline', async () => {
      // 0 agents online
      let avail = await caseService.getAvailability();
      expect(avail.chat.isAvailable).toBe(false);
      expect(avail.chat.activeAgentsCount).toBe(0);
      expect(avail.call.isAvailable).toBe(true);
      expect(avail.email.isAvailable).toBe(true);

      // 2 agents online
      mockRedisStore['support:agents:online'] = new Set(['agent-1', 'agent-2']);
      avail = await caseService.getAvailability();
      expect(avail.chat.isAvailable).toBe(true);
      expect(avail.chat.activeAgentsCount).toBe(2);
    });
  });

  describe('SupportQueueService', () => {
    it('allows agents to go online and offline cleanly in presence cache', async () => {
      await queueService.setAgentOnline('agent-1', 'Sarah Specialist');
      expect(mockRedisStore['support:agents:online']?.has('agent-1')).toBe(true);
      expect(mockRedisStore['support:agent:agent-1']?.status).toBe('ONLINE');

      await queueService.setAgentOffline('agent-1');
      expect(mockRedisStore['support:agents:online']?.has('agent-1')).toBe(false);
      expect(mockRedisStore['support:agent:agent-1']?.status).toBe('OFFLINE');
    });

    it('enqueues customer in chat queue and handles database persistence', async () => {
      const now = new Date();
      const mockCase = {
        id: 'c-1',
        ticket_number: 'FG-2026-99999',
        user_id: 'u-1',
        user_role: 'RIDER',
        trip_id: null,
        channel: SupportChannel.CHAT,
        category: SupportTicketCategory.SAFETY,
        subject: 'Safety concern',
        description: 'Driver speeding',
        status: SupportTicketStatus.OPEN,
        priority: SupportPriority.URGENT,
        created_at: now,
        updated_at: now,
      };

      const mockConv = {
        id: 'conv-1',
        case_id: 'c-1',
        user_id: 'u-1',
        agent_id: null,
        status: ConversationStatus.WAITING,
        webrtc_session_id: null,
        started_at: now,
        ended_at: null,
        created_at: now,
      };

      mockDbQuery
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ rows: [mockCase] }) // insert case
        .mockResolvedValueOnce({ rows: [mockConv] }) // insert conv
        .mockResolvedValueOnce({ rows: [] }) // insert outbox
        .mockResolvedValueOnce({ rows: [] }); // COMMIT

      const res = await queueService.enqueueCustomerForChat({
        userId: 'u-1',
        userRole: 'RIDER',
        category: SupportTicketCategory.SAFETY,
        subject: 'Safety concern',
        description: 'Driver speeding',
      });

      expect(res.case.priority).toBe(SupportPriority.URGENT);
      expect(res.conversation.status).toBe(ConversationStatus.WAITING);
      expect(res.queuePosition).toBe(1);
    });

    it('saves support chat message with correct sender role and delivery status', async () => {
      const now = new Date();
      const mockMsg = {
        id: 'm-1',
        conversation_id: 'conv-1',
        sender_id: 'u-1',
        sender_role: SenderRole.CUSTOMER,
        type: MessageType.TEXT,
        content: 'Hello, I need help with my trip',
        attachment_url: null,
        attachment_meta: null,
        delivery_status: DeliveryStatus.SENT,
        created_at: now,
      };

      mockDbQuery.mockResolvedValueOnce({ rows: [mockMsg] });

      const msg = await queueService.saveMessage({
        conversationId: 'conv-1',
        senderId: 'u-1',
        senderRole: SenderRole.CUSTOMER,
        type: MessageType.TEXT,
        content: 'Hello, I need help with my trip',
      });

      expect(msg.content).toBe('Hello, I need help with my trip');
      expect(msg.senderRole).toBe(SenderRole.CUSTOMER);
      expect(msg.deliveryStatus).toBe(DeliveryStatus.SENT);
    });
  });
});
