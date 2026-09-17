import type { Redis } from 'ioredis';
import { randomUUID } from 'node:crypto';
import { createLogger, type Logger } from '@fairgo/logger';

export interface MultiDeviceSyncPayload {
  userId: string;
  eventType: string;
  originDeviceId?: string;
  data: Record<string, unknown>;
}

export interface BroadcastEnvelope {
  eventId: string;
  eventType: string;
  sequenceNumber: number;
  originDeviceId: string;
  timestamp: string;
  data: Record<string, unknown>;
}

/**
 * Enterprise Multi-Device State Broadcaster.
 * Ensures consistent state across all connected devices belonging to a user.
 */
export class MultiDeviceBroadcaster {
  private readonly redis: Redis;
  private readonly logger: Logger;

  public constructor(redis: Redis, logger?: Logger) {
    this.redis = redis;
    this.logger = logger ?? createLogger('multi-device-sync');
  }

  /**
   * Broadcast a state update to all active devices of a user.
   * Increments a monotonic per-user sequence number in Redis to preserve strict order.
   */
  public async broadcastToUserDevices(payload: MultiDeviceSyncPayload): Promise<BroadcastEnvelope> {
    const seqKey = `seq:user:${payload.userId}`;
    const sequenceNumber = await this.redis.incr(seqKey);

    const envelope: BroadcastEnvelope = {
      eventId: randomUUID(),
      eventType: payload.eventType,
      sequenceNumber,
      originDeviceId: payload.originDeviceId ?? '',
      timestamp: new Date().toISOString(),
      data: payload.data,
    };

    const channel = `channel:user:${payload.userId}:sync`;
    await this.redis.publish(channel, JSON.stringify(envelope));

    this.logger.debug('Broadcasted multi-device sync event', {
      userId: payload.userId,
      code: payload.eventType,
      count: sequenceNumber,
    });

    return envelope;
  }
}
