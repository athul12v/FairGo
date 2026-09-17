import 'dotenv/config';
import path from 'path';
import dotenv from 'dotenv';
import { createApp } from './http/app.js';
import { closeDb, closeRedis } from './infrastructure/database.js';
import { createLogger } from '@fairgo/logger';

// Load .env from service directory or workspace root
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config({ path: path.resolve(process.cwd(), '../../.env') });

const log = createLogger('auth-service');

const rawPort = process.env['AUTH_SERVICE_PORT'] ?? process.env['PORT'];
if (!rawPort) {
  throw new Error('Neither AUTH_SERVICE_PORT nor PORT is defined in .env');
}
const PORT = parseInt(rawPort, 10);

async function main(): Promise<void> {
  // Validate required environment variables
  const required = ['DATABASE_URL', 'REDIS_URL', 'JWT_SECRET'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    log.fatal(`Missing required environment variables: ${missing.join(', ')}`, {});
    process.exit(1);
  }

  const app = await createApp();

  const server = app.listen(PORT, () => {
    log.info(`Auth service listening`, { port: PORT, env: process.env['NODE_ENV'] ?? 'development' });
  });

  // ----------------------------------------------------------
  // Graceful shutdown
  // ----------------------------------------------------------
  const shutdown = async (signal: string): Promise<void> => {
    log.info(`Received ${signal}, shutting down gracefully`, {});

    // Stop accepting new connections
    server.close(async () => {
      try {
        await closeDb();
        await closeRedis();
        log.info('Auth service shut down cleanly', {});
        process.exit(0);
      } catch (err) {
        log.error('Error during shutdown', { err: err as Error });
        process.exit(1);
      }
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
      log.error('Forced shutdown after timeout', {});
      process.exit(1);
    }, 10_000);
  };

  process.on('SIGTERM', () => { void shutdown('SIGTERM'); });
  process.on('SIGINT', () => { void shutdown('SIGINT'); });

  // Unhandled rejection safety net
  process.on('unhandledRejection', (reason) => {
    log.error('Unhandled promise rejection', { err: reason as Error });
    // Don't exit — log and continue (operational resilience)
  });

  process.on('uncaughtException', (err) => {
    log.fatal('Uncaught exception', { err });
    void shutdown('uncaughtException');
  });
}

main().catch((err: unknown) => {
  console.error('Failed to start auth service:', err);
  process.exit(1);
});
