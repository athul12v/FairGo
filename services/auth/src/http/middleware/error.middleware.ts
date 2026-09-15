import type { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';
import { ZodError } from 'zod';
import { isDomainError } from '@fairgo/domain-errors';
import { createLogger } from '@fairgo/logger';

const log = createLogger('auth-service:error');

/**
 * Injects X-Request-ID and X-Correlation-ID headers on every request.
 * Attaches to req.requestId and req.correlationId for downstream logging.
 */
export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId = (req.headers['x-request-id'] as string | undefined) ?? randomUUID();
  const correlationId = (req.headers['x-correlation-id'] as string | undefined) ?? randomUUID();

  req.requestId = requestId;
  req.correlationId = correlationId;

  res.setHeader('X-Request-ID', requestId);
  res.setHeader('X-Correlation-ID', correlationId);

  next();
}

/**
 * Global error handler — converts DomainErrors and ZodErrors to structured JSON.
 * Non-operational errors are logged as fatal (potential bugs).
 */
export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
): void {
  const requestId = req.requestId ?? 'unknown';

  // Zod validation errors
  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: {
        code: 'ERR_VALIDATION',
        message: 'Request validation failed',
        details: err.errors.map((e) => ({ field: e.path.join('.'), message: e.message })),
        requestId,
      },
    });
    return;
  }

  // Domain errors (operational — expected business errors)
  if (isDomainError(err)) {
    if (!err.isOperational) {
      log.error('Non-operational domain error', { err, requestId });
    } else {
      log.warn('Domain error', { code: err.code, message: err.message, requestId });
    }

    res.status(err.httpStatus).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        requestId,
        ...(process.env['NODE_ENV'] !== 'production' && { details: err.details }),
      },
    });
    return;
  }

  // Unknown / unexpected errors
  log.error('Unhandled error', { err: err as Error, requestId });

  res.status(500).json({
    success: false,
    error: {
      code: 'ERR_INTERNAL',
      message: 'An internal error occurred. Please try again.',
      requestId,
    },
  });
}
