import type { Redis } from 'ioredis';
import { createLogger, type Logger } from '@fairgo/logger';

export interface InboxRecord {
  eventId: string;
  processedAt: number;
}

/**
 * Consumer Inbox Deduplicator.
 * Guarantees exactly-once processing of asynchronous messages/events across pods.
 */
export class ConsumerInboxDeduplicator {
  private readonly redis: Redis;
  private readonly ttlSeconds: number;
  private readonly logger: Logger;

  public constructor(redis: Redis, ttlSeconds = 604800, logger?: Logger) { // 7 days default TTL
    this.redis = redis;
    this.ttlSeconds = ttlSeconds;
    this.logger = logger ?? createLogger('consumer-inbox');
  }

  /**
   * Check and record event processing atomically.
   * Returns true if the event is NEW and should be processed.
   * Returns false if the event has ALREADY been processed (duplicate).
   */
  public async tryRecordProcessing(eventId: string, consumerGroup: string): Promise<boolean> {
    const key = `inbox:${consumerGroup}:${eventId}`;
    const acquired = await this.redis.set(
      key,
      JSON.stringify({ eventId, processedAt: Date.now() } satisfies InboxRecord),
      'EX',
      this.ttlSeconds,
      'NX',
    );

    if (!acquired) {
      this.logger.info('Duplicate event suppressed by Consumer Inbox', {
        code: eventId,
        actorId: consumerGroup,
      });
      return false;
    }

    return true;
  }
}
