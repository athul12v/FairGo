import type { Redis } from 'ioredis';
import { randomUUID } from 'node:crypto';
import { createLogger, type Logger } from '@fairgo/logger';

export interface LockOptions {
  ttlMs?: number;
  retryAttempts?: number;
  retryDelayMs?: number;
  autoRenew?: boolean;
}

export interface LockHandle {
  key: string;
  token: string;
  ttlMs: number;
  renew: () => Promise<boolean>;
  release: () => Promise<boolean>;
}

const RELEASE_LUA = `
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
`;

const RENEW_LUA = `
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("pexpire", KEYS[1], ARGV[2])
else
    return 0
end
`;

export class DistributedLockManager {
  private readonly redis: Redis;
  private readonly logger: Logger;

  public constructor(redis: Redis, logger?: Logger) {
    this.redis = redis;
    this.logger = logger ?? createLogger('distributed-lock');
  }

  /**
   * Acquire a distributed lock with retry backoff.
   */
  public async acquire(
    lockKey: string,
    options: LockOptions = {},
  ): Promise<LockHandle | null> {
    const ttlMs = options.ttlMs ?? 5000;
    const retryAttempts = options.retryAttempts ?? 3;
    const retryDelayMs = options.retryDelayMs ?? 150;
    const token = randomUUID();
    const fullKey = `lock:${lockKey}`;

    for (let attempt = 1; attempt <= retryAttempts; attempt++) {
      // SET key token NX PX ttlMs
      const result = await this.redis.set(fullKey, token, 'PX', ttlMs, 'NX');

      if (result === 'OK') {
        const handle: LockHandle = {
          key: fullKey,
          token,
          ttlMs,
          renew: async (): Promise<boolean> => {
            const res = await this.redis.eval(RENEW_LUA, 1, fullKey, String(ttlMs));
            return res === 1;
          },
          release: async (): Promise<boolean> => {
            const res = await this.redis.eval(RELEASE_LUA, 1, fullKey, token);
            return res === 1;
          },
        };

        return handle;
      }

      if (attempt < retryAttempts) {
        const jitter = Math.floor(Math.random() * 50);
        await new Promise((resolve) => setTimeout(resolve, retryDelayMs + jitter));
      }
    }

    return null;
  }

  /**
   * Execute an async function exclusively within a distributed lock.
   */
  public async withLock<T>(
    lockKey: string,
    fn: (handle: LockHandle) => Promise<T>,
    options: LockOptions = {},
  ): Promise<T> {
    const handle = await this.acquire(lockKey, options);
    if (!handle) {
      throw new Error(`CONCURRENCY_CONFLICT: Could not acquire lock for '${lockKey}'`);
    }

    let renewTimer: NodeJS.Timeout | null = null;
    if (options.autoRenew) {
      const intervalMs = Math.floor(handle.ttlMs / 2);
      renewTimer = setInterval(async () => {
        try {
          const success = await handle.renew();
          if (!success) {
            this.logger.warn('Failed to renew distributed lock', { code: lockKey });
          }
        } catch (err) {
          this.logger.error('Error renewing distributed lock', { err, code: lockKey });
        }
      }, intervalMs);
    }

    try {
      return await fn(handle);
    } finally {
      if (renewTimer) {
        clearInterval(renewTimer);
      }
      try {
        await handle.release();
      } catch (err) {
        this.logger.error('Failed to release distributed lock', { err, code: lockKey });
      }
    }
  }
}
