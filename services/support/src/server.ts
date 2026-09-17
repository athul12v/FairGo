import 'dotenv/config';
import path from 'path';
import dotenv from 'dotenv';
import http from 'http';
import { createApp } from './http/app.js';
import { SupportCaseService } from './domain/support-case.service.js';
import { SupportQueueService } from './domain/support-queue.service.js';
import { RealtimeGateway } from './infrastructure/realtime-gateway.js';
import { closeDb, closeRedis } from './infrastructure/database.js';
import { createLogger } from '@fairgo/logger';

// Load .env from service directory or workspace root
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config({ path: path.resolve(process.cwd(), '../../.env') });

const log = createLogger('support-service');

const requiredEnvVars = ['DATABASE_URL', 'REDIS_URL'];
const missing = requiredEnvVars.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(`Missing required environment variables in .env: ${missing.join(', ')}`);
}

const rawPort = process.env['SUPPORT_SERVICE_PORT'] ?? process.env['PORT'];
if (!rawPort) {
  throw new Error('Neither SUPPORT_SERVICE_PORT nor PORT is defined in .env');
}
const PORT = parseInt(rawPort, 10);

async function main(): Promise<void> {
  const caseService = new SupportCaseService();
  const queueService = new SupportQueueService();

  const app = createApp(caseService, queueService);
  const server = http.createServer(app);

  // Initialize Realtime WebSocket & WebRTC Gateway on the HTTP server
  new RealtimeGateway(server, queueService);

  server.listen(PORT, () => {
    log.info(`Support service listening on port ${PORT}`, {
      port: PORT,
      message: `Console: http://localhost:${PORT}/agent-console | WS: ws://localhost:${PORT}/ws/support`,
    });
  });

  // Graceful shutdown
  const shutdown = async (signal: string): Promise<void> => {
    log.info(`Received ${signal}, shutting down support service gracefully`, {});
    server.close(async () => {
      try {
        await closeDb();
        await closeRedis();
        log.info('Support service shut down cleanly', {});
        process.exit(0);
      } catch (err) {
        log.error('Error during shutdown', { err: err as Error });
        process.exit(1);
      }
    });

    setTimeout(() => {
      log.error('Forced shutdown after timeout', {});
      process.exit(1);
    }, 10_000);
  };

  process.on('SIGTERM', () => { void shutdown('SIGTERM'); });
  process.on('SIGINT', () => { void shutdown('SIGINT'); });
  process.on('unhandledRejection', (reason: unknown) => {
    log.error('Unhandled promise rejection in support service', { err: reason as Error });
  });
}

void main();
