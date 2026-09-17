import type { Request, Response, NextFunction } from 'express';
import type { Redis } from 'ioredis';
import { createLogger, type Logger } from '@fairgo/logger';

export interface IdempotencyConfig {
  redis: Redis;
  ttlSeconds?: number;
  headerName?: string;
  enforceOnMethods?: string[];
  logger?: Logger;
}

interface StoredResponse {
  status: 'PROCESSING' | 'COMPLETED';
  statusCode?: number;
  headers?: Record<string, string>;
  body?: unknown;
  createdAt: number;
}

/**
 * Enterprise Idempotency Middleware for Express.
 * Prevents race conditions and duplicate executions across single or multiple devices.
 */
export function createIdempotencyMiddleware(config: IdempotencyConfig) {
  const {
    redis,
    ttlSeconds = 86400, // 24 hours
    headerName = 'x-idempotency-key',
    enforceOnMethods = ['POST', 'PUT', 'PATCH', 'DELETE'],
    logger = createLogger('idempotency'),
  } = config;

  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const method = req.method.toUpperCase();
    if (!enforceOnMethods.includes(method)) {
      next();
      return;
    }

    const idempotencyKey = req.headers[headerName.toLowerCase()] as string | undefined;
    if (!idempotencyKey) {
      next();
      return;
    }

    // Extract user ID from authenticated request if present
    const userId = (req as Request & { user?: { id: string } }).user?.id ?? 'anonymous';
    const redisKey = `idempotency:${userId}:${idempotencyKey}`;

    try {
      // Check existing idempotency record
      const raw = await redis.get(redisKey);

      if (raw) {
        const stored: StoredResponse = JSON.parse(raw);

        if (stored.status === 'PROCESSING') {
          // Another request with the same idempotency key is currently running
          res.status(409).json({
            success: false,
            error: {
              code: 'ERR_CONCURRENT_REQUEST',
              message: 'A request with this idempotency key is currently processing. Please wait.',
            },
          });
          return;
        }

        if (stored.status === 'COMPLETED' && stored.statusCode) {
          // Replay cached response
          res.setHeader('X-Cache-Lookup', 'IDEMPOTENT_HIT');
          if (stored.headers) {
            for (const [k, v] of Object.entries(stored.headers)) {
              res.setHeader(k, v);
            }
          }
          res.status(stored.statusCode).send(stored.body);
          return;
        }
      }

      // Mark as PROCESSING with a 30-second lease
      const acquired = await redis.set(
        redisKey,
        JSON.stringify({
          status: 'PROCESSING',
          createdAt: Date.now(),
        } satisfies StoredResponse),
        'EX',
        30,
        'NX',
      );

      if (!acquired) {
        res.status(409).json({
          success: false,
          error: {
            code: 'ERR_CONCURRENT_REQUEST',
            message: 'Concurrent request collision detected. Please retry.',
          },
        });
        return;
      }

      // Hook response sending to capture result
      const originalSend = res.send.bind(res);
      const originalJson = res.json.bind(res);

      const saveCompleted = async (body: unknown, statusCode: number): Promise<void> => {
        try {
          const payload: StoredResponse = {
            status: 'COMPLETED',
            statusCode,
            body,
            createdAt: Date.now(),
          };
          await redis.set(redisKey, JSON.stringify(payload), 'EX', ttlSeconds);
        } catch (err) {
          logger.error('Failed to save idempotency response to Redis', { err, code: redisKey });
        }
      };

      res.send = function (body?: unknown): Response {
        const statusCode = res.statusCode || 200;
        void saveCompleted(body, statusCode);
        return originalSend(body);
      };

      res.json = function (body?: unknown): Response {
        const statusCode = res.statusCode || 200;
        void saveCompleted(body, statusCode);
        return originalJson(body);
      };

      next();
    } catch (err) {
      logger.error('Error executing idempotency middleware', { err, code: idempotencyKey });
      next(err);
    }
  };
}
