import { createLogger, type Logger } from '@fairgo/logger';

export interface VersionedEntity {
  id: string;
  version: number;
}

export class OptimisticLockError extends Error {
  public readonly entityId: string;
  public readonly expectedVersion: number;

  public constructor(entityId: string, expectedVersion: number) {
    super(`Optimistic concurrency conflict on entity '${entityId}' (expected version: ${expectedVersion})`);
    this.name = 'OptimisticLockError';
    this.entityId = entityId;
    this.expectedVersion = expectedVersion;
  }
}

/**
 * Optimistic Concurrency Control update executor with automatic retry.
 */
export async function executeWithOptimisticLock<T extends VersionedEntity>(
  fetchEntity: () => Promise<T | null>,
  applyMutation: (entity: T) => Promise<boolean>,
  maxRetries = 3,
  logger: Logger = createLogger('optimistic-lock'),
): Promise<void> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    const entity = await fetchEntity();
    if (!entity) {
      throw new Error('Entity not found');
    }

    const success = await applyMutation(entity);
    if (success) {
      return;
    }

    logger.warn('Optimistic lock contention detected, retrying...', {
      code: entity.id,
      count: attempt,
    });

    if (attempt < maxRetries) {
      const backoffMs = Math.floor(Math.random() * 50) + attempt * 20;
      await new Promise((resolve) => setTimeout(resolve, backoffMs));
    }
  }

  throw new OptimisticLockError('UNKNOWN', -1);
}
