import { Pool } from 'pg';
import { createClient } from 'redis';
import { createLogger } from '@fairgo/logger';

const log = createLogger('auth-service');

// ----------------------------------------------------------
// PostgreSQL connection pool
// ----------------------------------------------------------
let pgPool: Pool | null = null;

export function getDb(): Pool {
  if (!pgPool) {
    pgPool = new Pool({
      connectionString: process.env['DATABASE_URL'],
      max: 20,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
    });

    pgPool.on('error', (err: Error) => {
      log.error('Unexpected PostgreSQL pool error', { err });
    });
  }
  return pgPool;
}

export async function closeDb(): Promise<void> {
  if (pgPool) {
    await pgPool.end();
    pgPool = null;
  }
}

// ----------------------------------------------------------
// Redis client
// ----------------------------------------------------------
let redisClient: ReturnType<typeof createClient> | null = null;

export async function getRedis(): Promise<ReturnType<typeof createClient>> {
  if (!redisClient) {
    const redisUrl = process.env['REDIS_URL'];
    if (!redisUrl) {
      throw new Error('REDIS_URL is not defined in .env');
    }
    redisClient = createClient({
      url: redisUrl,
      socket: {
        reconnectStrategy: (retries: number) => Math.min(retries * 100, 5_000),
      },
    });

    redisClient.on('error', (err: Error) => {
      log.error('Redis client error', { err });
    });

    redisClient.on('connect', () => {
      log.info('Redis connected');
    });

    await redisClient.connect();
  }
  return redisClient;
}

export async function closeRedis(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
  }
}
