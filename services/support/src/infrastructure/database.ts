// services/support/src/infrastructure/database.ts

import pg from 'pg';
import { createClient } from 'redis';
import { createLogger } from '@fairgo/logger';

const { Pool } = pg;
const log = createLogger('support-service');

let pool: pg.Pool | null = null;
let redisClient: ReturnType<typeof createClient> | null = null;

export function getDb(): pg.Pool {
  if (!pool) {
    const connectionString = process.env['DATABASE_URL'];
    if (!connectionString) {
      throw new Error('DATABASE_URL is not defined in .env');
    }
    pool = new Pool({
      connectionString,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
    pool.on('error', (err: Error) => {
      log.error('Unexpected error on idle PostgreSQL client', { err });
    });
  }
  return pool;
}

export async function getRedis(): Promise<ReturnType<typeof createClient>> {
  if (!redisClient) {
    const url = process.env['REDIS_URL'];
    if (!url) {
      throw new Error('REDIS_URL is not defined in .env');
    }
    redisClient = createClient({ url });
    redisClient.on('error', (err: Error) => {
      log.error('Redis client error', { err });
    });
    await redisClient.connect();
  }
  return redisClient;
}

export async function closeDb(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

export async function closeRedis(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
  }
}
