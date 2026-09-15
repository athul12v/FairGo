// services/support/src/http/agent.controller.ts

import { Router, type Request, type Response } from 'express';
import { SupportCaseService } from '../domain/support-case.service.js';
import { SupportQueueService } from '../domain/support-queue.service.js';
import { SupportTicketStatus, type UUID } from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';

const log = createLogger('agent-controller');

export function createAgentRouter(
  caseService: SupportCaseService,
  queueService: SupportQueueService
): Router {
  const router = Router();

  // 1. Get Waiting Chat Queue
  router.get('/queue', async (_req: Request, res: Response): Promise<void> => {
    try {
      const queue = await queueService.getWaitingQueue();
      res.json({ success: true, data: queue });
    } catch (err) {
      log.error('Failed to get waiting queue', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 2. Accept a waiting conversation
  router.post('/conversations/:id/accept', async (req: Request, res: Response): Promise<void> => {
    try {
      const conversationId = req.params['id'] as UUID;
      const agentId = (req.headers['x-user-id'] as string) ?? req.body.agentId ?? 'agent-101';
      const agentName = (req.headers['x-user-name'] as string) ?? req.body.agentName ?? 'Sarah M.';

      const conversation = await queueService.acceptConversation(agentId, agentName, conversationId);
      res.json({ success: true, data: conversation });
    } catch (err) {
      log.error('Failed to accept conversation', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 3. Get Active Conversations for Agent
  router.get('/conversations/active', async (req: Request, res: Response): Promise<void> => {
    try {
      const agentId = (req.headers['x-user-id'] as string) ?? (req.query['agentId'] as string) ?? 'agent-101';
      const active = await queueService.getActiveConversations(agentId);
      res.json({ success: true, data: active });
    } catch (err) {
      log.error('Failed to get active conversations', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 4. Add Internal Agent Note (strictly agent-only, hidden from customer)
  router.post('/cases/:id/notes', async (req: Request, res: Response): Promise<void> => {
    try {
      const caseId = req.params['id'] as UUID;
      const agentId = (req.headers['x-user-id'] as string) ?? req.body.agentId ?? 'agent-101';
      const { note } = req.body;

      if (!note) {
        res.status(400).json({ success: false, error: { message: 'Note is required' } });
        return;
      }

      await caseService.addInternalNote(caseId, agentId, note);
      res.json({ success: true, message: 'Internal note saved' });
    } catch (err) {
      log.error('Failed to add internal note', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 5. Update Case Status (Resolve, Close)
  router.post('/cases/:id/status', async (req: Request, res: Response): Promise<void> => {
    try {
      const caseId = req.params['id'] as UUID;
      const { status } = req.body;

      if (!status || !Object.values(SupportTicketStatus).includes(status)) {
        res.status(400).json({ success: false, error: { message: 'Valid status is required' } });
        return;
      }

      await caseService.updateCaseStatus(caseId, status as SupportTicketStatus);
      res.json({ success: true, message: `Case status updated to ${status}` });
    } catch (err) {
      log.error('Failed to update case status', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  return router;
}
