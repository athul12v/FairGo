import pino from 'pino';

export type LogLevel = 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal';

// Using unknown for err and index signature to allow Error objects without TypeScript conflicts
export type LogContextValue = string | number | boolean | Error | unknown;

export interface LogContext {
  service?: string;
  requestId?: string;
  correlationId?: string;
  userId?: string;
  riderId?: string;
  driverId?: string;
  tripId?: string;
  err?: unknown;
  code?: string;
  port?: number;
  env?: string;
  role?: string;
  sessionId?: string;
  otp?: string;
  rateLimitKey?: string;
  vehicleType?: string;
  distanceMeters?: number;
  durationSeconds?: number;
  surgeMultiplierBps?: number;
  estimatedFarePaise?: number;
  radiusMeters?: number;
  count?: number;
  actorId?: string;
  message?: string;
  conversationId?: string;
  ticketNumber?: string;
  caseId?: string;
  agentId?: string;
}

export interface Logger {
  trace(msg: string, ctx?: LogContext): void;
  debug(msg: string, ctx?: LogContext): void;
  info(msg: string, ctx?: LogContext): void;
  warn(msg: string, ctx?: LogContext): void;
  error(msg: string, ctx?: LogContext): void;
  fatal(msg: string, ctx?: LogContext): void;
  child(bindings: LogContext): Logger;
}

const isDev = process.env['NODE_ENV'] !== 'production';

/**
 * Creates a structured logger instance for a FairGo service.
 * Uses pino for production (JSON output) and pino-pretty for development.
 *
 * IMPORTANT: Never log PII (phone numbers, emails, card data, GPS coordinates).
 */
export function createLogger(
  serviceName: string,
  defaultContext: Partial<LogContext> = {},
): Logger {
  const pinoLogger = pino(
    {
      level: process.env['LOG_LEVEL'] ?? 'info',
      base: {
        service: serviceName,
        env: process.env['NODE_ENV'] ?? 'development',
        ...defaultContext,
      },
      timestamp: pino.stdTimeFunctions.isoTime,
      formatters: {
        level(label) {
          return { level: label };
        },
      },
    },
    isDev
      ? pino.transport({
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'HH:MM:ss',
            ignore: 'pid,hostname',
          },
        })
      : undefined,
  );

  return adaptLogger(pinoLogger);
}

function adaptLogger(pinoInst: pino.Logger): Logger {
  return {
    trace: (msg, ctx) => pinoInst.trace(ctx ?? {}, msg),
    debug: (msg, ctx) => pinoInst.debug(ctx ?? {}, msg),
    info: (msg, ctx) => pinoInst.info(ctx ?? {}, msg),
    warn: (msg, ctx) => pinoInst.warn(ctx ?? {}, msg),
    error: (msg, ctx) => {
      const { err, ...rest } = ctx ?? {};
      pinoInst.error({ err, ...rest }, msg);
    },
    fatal: (msg, ctx) => {
      const { err, ...rest } = ctx ?? {};
      pinoInst.fatal({ err, ...rest }, msg);
    },
    child: (bindings) => adaptLogger(pinoInst.child(bindings as Record<string, unknown>)),
  };
}

export { createLogger as default };
