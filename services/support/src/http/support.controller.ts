// services/support/src/http/support.controller.ts

import { Router, type Request, type Response } from 'express';
import { SupportCaseService } from '../domain/support-case.service.js';
import { SupportQueueService } from '../domain/support-queue.service.js';
import { SupportTicketCategory, type UUID } from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';

const log = createLogger('support-controller');

export function createSupportRouter(
  caseService: SupportCaseService,
  queueService: SupportQueueService
): Router {
  const router = Router();

  // 1. Get real-time availability
  router.get('/availability', async (_req: Request, res: Response): Promise<void> => {
    try {
      const availability = await caseService.getAvailability();
      res.json({ success: true, data: availability });
    } catch (err) {
      log.error('Failed to get availability', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 2. Get FAQs (Self-help, Google style)
  router.get('/faqs', async (req: Request, res: Response): Promise<void> => {
    try {
      const category = req.query['category'] as SupportTicketCategory | undefined;
      const faqs = await caseService.getFaqs(category);
      res.json({ success: true, data: faqs });
    } catch (err) {
      log.error('Failed to get FAQs', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 3. Submit Email Support Request
  router.post('/cases/email', async (req: Request, res: Response): Promise<void> => {
    try {
      const { category, subject, description, tripId, attachments } = req.body;
      const userId = (req.headers['x-user-id'] as string) ?? req.body.userId;
      const userRole = ((req.headers['x-user-role'] as string) ?? 'RIDER') as 'RIDER' | 'DRIVER';

      if (!subject || !description || !category) {
        res.status(400).json({
          success: false,
          error: { message: 'Category, subject, and description are required' },
        });
        return;
      }

      const supportCase = await caseService.createEmailCase({
        userId: userId ?? 'guest-user',
        userRole,
        tripId,
        category: category as SupportTicketCategory,
        subject,
        description,
        attachments,
      });

      res.status(201).json({ success: true, data: supportCase });
    } catch (err) {
      log.error('Failed to create email case', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 4. Request Phone Callback
  router.post('/cases/callback', async (req: Request, res: Response): Promise<void> => {
    try {
      const { phoneNumber, preferredTimeWindow, category, issueSummary, tripId } = req.body;
      const userId = (req.headers['x-user-id'] as string) ?? req.body.userId;
      const userRole = ((req.headers['x-user-role'] as string) ?? 'RIDER') as 'RIDER' | 'DRIVER';

      if (!phoneNumber || !preferredTimeWindow || !issueSummary) {
        res.status(400).json({
          success: false,
          error: { message: 'Phone number, preferred time window, and issue summary are required' },
        });
        return;
      }

      const result = await caseService.requestCallback({
        userId: userId ?? 'guest-user',
        userRole,
        phoneNumber,
        preferredTimeWindow,
        category: (category as SupportTicketCategory) ?? SupportTicketCategory.OTHER,
        issueSummary,
        tripId,
      });

      res.status(201).json({ success: true, data: result });
    } catch (err) {
      log.error('Failed to request callback', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 5. Initiate Live Chat & Queueing
  router.post('/chat/initiate', async (req: Request, res: Response): Promise<void> => {
    try {
      const { category, subject, description, tripId } = req.body;
      const userId = (req.headers['x-user-id'] as string) ?? req.body.userId ?? `user-${Date.now()}`;
      const userRole = ((req.headers['x-user-role'] as string) ?? 'RIDER') as 'RIDER' | 'DRIVER';

      const result = await queueService.enqueueCustomerForChat({
        userId,
        userRole,
        category: (category as SupportTicketCategory) ?? SupportTicketCategory.OTHER,
        subject: subject ?? 'Live Chat Support',
        description: description ?? 'Customer initiated live chat.',
        tripId,
      });

      res.status(201).json({ success: true, data: result });
    } catch (err) {
      log.error('Failed to initiate live chat', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 6. Get Customer's Cases
  router.get('/cases/my', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = (req.headers['x-user-id'] as string) ?? (req.query['userId'] as string);
      if (!userId) {
        res.status(400).json({ success: false, error: { message: 'userId is required' } });
        return;
      }

      const cases = await caseService.getUserCases(userId);
      res.json({ success: true, data: cases });
    } catch (err) {
      log.error('Failed to get user cases', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  // 7. File Upload Endpoint (for screenshots/attachments)
  router.post('/upload', async (req: Request, res: Response): Promise<void> => {
    try {
      const { fileName, fileData, mimeType } = req.body;
      // In production, uploads to S3/Cloud Storage. Here we provide a secured URL.
      const id = `att-${Date.now()}`;
      const mockUrl = `https://storage.fairgo.in/support-attachments/${id}-${fileName ?? 'screenshot.png'}`;

      res.json({
        success: true,
        data: {
          url: mockUrl,
          fileName: fileName ?? 'screenshot.png',
          fileSize: fileData ? Buffer.from(fileData, 'base64').length : 1024,
          mimeType: mimeType ?? 'image/png',
        },
      });
    } catch (err) {
      log.error('Failed to upload file', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Upload failed' } });
    }
  });

  // 8. Submit CSAT Rating
  router.post('/csat', async (req: Request, res: Response): Promise<void> => {
    try {
      const { caseId, rating, comment } = req.body;
      if (!caseId || !rating) {
        res.status(400).json({ success: false, error: { message: 'caseId and rating (1-5) are required' } });
        return;
      }

      await queueService.submitCsat(caseId as UUID, Number(rating), comment);
      res.json({ success: true, message: 'Thank you for your feedback!' });
    } catch (err) {
      log.error('Failed to submit CSAT', { err: err as Error });
      res.status(500).json({ success: false, error: { message: 'Internal server error' } });
    }
  });

  return router;
}
