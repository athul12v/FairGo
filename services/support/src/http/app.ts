// services/support/src/http/app.ts

import express, { type Express, type Request, type Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { SupportCaseService } from '../domain/support-case.service.js';
import { SupportQueueService } from '../domain/support-queue.service.js';
import { createSupportRouter } from './support.controller.js';
import { createAgentRouter } from './agent.controller.js';

export function createApp(
  caseService: SupportCaseService,
  queueService: SupportQueueService
): Express {
  const app = express();

  // Middleware
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors());
  app.use(express.json({ limit: '15mb' }));
  app.use(express.urlencoded({ extended: true, limit: '15mb' }));

  // Static files for Agent Web Console
  const publicDir = path.resolve(process.cwd(), 'public');
  app.use('/agent-console', express.static(publicDir));

  // Health checks
  app.get('/health/live', (_req: Request, res: Response): void => {
    res.json({ status: 'ok' });
  });
  app.get('/health/ready', (_req: Request, res: Response): void => {
    res.json({ status: 'ready' });
  });

  // API Routers
  app.use('/v1/support', createSupportRouter(caseService, queueService));
  app.use('/v1/agent', createAgentRouter(caseService, queueService));

  return app;
}
