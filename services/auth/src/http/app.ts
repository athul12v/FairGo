import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { collectDefaultMetrics, Registry } from 'prom-client';
import { createLogger } from '@fairgo/logger';
import { getDb, getRedis } from '../infrastructure/database.js';
import { OtpService } from '../domain/otp.service.js';
import { AuthService } from '../domain/auth.service.js';
import { AuthController } from './auth.controller.js';
import { createAuthRouter } from './auth.router.js';
import { requestIdMiddleware, errorHandler } from './middleware/error.middleware.js';

const log = createLogger('auth-service');

export async function createApp(): Promise<express.Application> {
  const app = express();

  // ----------------------------------------------------------
  // Security headers
  // ----------------------------------------------------------
  app.use(helmet({
    contentSecurityPolicy: true,
    crossOriginEmbedderPolicy: false, // APIs don't need this
  }));

  // ----------------------------------------------------------
  // CORS
  // ----------------------------------------------------------
  const allowedOrigins = (process.env['ALLOWED_ORIGINS'] ?? 'http://localhost:3000').split(',');
  app.use(cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error(`Origin ${origin} not allowed by CORS`));
      }
    },
    credentials: true,
  }));

  // ----------------------------------------------------------
  // Body parsing
  // ----------------------------------------------------------
  app.use(express.json({ limit: '10kb' })); // tight limit — auth requests are small
  app.use(express.urlencoded({ extended: false }));

  // ----------------------------------------------------------
  // Request ID injection
  // ----------------------------------------------------------
  app.use(requestIdMiddleware);

  // ----------------------------------------------------------
  // Prometheus metrics
  // ----------------------------------------------------------
  const metricsRegistry = new Registry();
  collectDefaultMetrics({ register: metricsRegistry });

  app.get('/metrics', async (_req, res) => {
    res.set('Content-Type', metricsRegistry.contentType);
    res.end(await metricsRegistry.metrics());
  });

  // ----------------------------------------------------------
  // Health checks
  // ----------------------------------------------------------
  app.get('/health/live', (_req, res) => {
    res.json({ status: 'ok', service: 'auth', timestamp: new Date().toISOString() });
  });

  app.get('/health/ready', async (_req, res) => {
    try {
      // Check DB connectivity
      await getDb().query('SELECT 1');
      // Check Redis connectivity
      const redis = await getRedis();
      await (redis as any).ping();
      res.json({ status: 'ready', service: 'auth' });
    } catch (err) {
      log.error('Health check failed', { err: err as Error });
      res.status(503).json({ status: 'not-ready', service: 'auth' });
    }
  });

  // ----------------------------------------------------------
  // Wire up dependencies
  // ----------------------------------------------------------
  const db = getDb();
  const redis = await getRedis();
  const otpService = new OtpService(redis, db);
  const authService = new AuthService(db, otpService);
  const authController = new AuthController(authService);
  const authRouter = createAuthRouter(authController);

  // ----------------------------------------------------------
  // Routes
  // ----------------------------------------------------------
  app.use('/v1/auth', authRouter);

  // 404 handler
  app.use((_req, res) => {
    res.status(404).json({
      success: false,
      error: { code: 'ERR_NOT_FOUND', message: 'Route not found' },
    });
  });

  // ----------------------------------------------------------
  // Global error handler (must be last)
  // ----------------------------------------------------------
  app.use(errorHandler);

  return app;
}
