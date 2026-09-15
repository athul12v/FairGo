import { TripInvalidStateTransitionError } from '@fairgo/domain-errors';
import type { TripStatus } from '@fairgo/shared-types';

/**
 * Trip State Machine
 *
 * Defines valid transitions for a trip's lifecycle.
 * This is the single source of truth for what state changes are allowed.
 * Any code attempting an invalid transition will receive TripInvalidStateTransitionError.
 *
 * State diagram:
 *
 *   SEARCHING ──────────────────────────────────────────────────► NO_DRIVER_FOUND
 *       │
 *       ▼
 *   DRIVER_ASSIGNED ─────────────────────────────────────────────► CANCELLED_BY_RIDER
 *       │                                                         ► CANCELLED_BY_DRIVER
 *       ▼                                                         ► CANCELLED_BY_SYSTEM
 *   DRIVER_EN_ROUTE ────────────────────────────────────────────►  (same cancellations)
 *       │
 *       ▼
 *   DRIVER_ARRIVED ──────────────────────────────────────────────► (same cancellations)
 *       │
 *       ▼
 *   IN_PROGRESS (OTP verified — cannot cancel, only complete)
 *       │
 *       ▼
 *   COMPLETED
 */
export class TripStateMachine {
  // Maps each state to the set of valid next states
  private static readonly VALID_TRANSITIONS: Readonly<
    Record<TripStatus, ReadonlySet<TripStatus>>
  > = {
    SEARCHING: new Set<TripStatus>([
      'DRIVER_ASSIGNED',
      'NO_DRIVER_FOUND',
      'CANCELLED_BY_RIDER',
      'CANCELLED_BY_SYSTEM',
    ]),
    DRIVER_ASSIGNED: new Set<TripStatus>([
      'DRIVER_EN_ROUTE',
      'CANCELLED_BY_RIDER',
      'CANCELLED_BY_DRIVER',
      'CANCELLED_BY_SYSTEM',
    ]),
    DRIVER_EN_ROUTE: new Set<TripStatus>([
      'DRIVER_ARRIVED',
      'CANCELLED_BY_RIDER',
      'CANCELLED_BY_DRIVER',
      'CANCELLED_BY_SYSTEM',
    ]),
    DRIVER_ARRIVED: new Set<TripStatus>([
      'IN_PROGRESS',
      'CANCELLED_BY_RIDER',
      'CANCELLED_BY_DRIVER',
      'CANCELLED_BY_SYSTEM',
    ]),
    IN_PROGRESS: new Set<TripStatus>([
      'COMPLETED',
      'CANCELLED_BY_SYSTEM', // emergency/admin only
    ]),
    COMPLETED: new Set<TripStatus>([]),  // terminal
    CANCELLED_BY_RIDER: new Set<TripStatus>([]),   // terminal
    CANCELLED_BY_DRIVER: new Set<TripStatus>([]),  // terminal
    CANCELLED_BY_SYSTEM: new Set<TripStatus>([]),  // terminal
    NO_DRIVER_FOUND: new Set<TripStatus>([]),       // terminal
  };

  /**
   * Validates that a transition from `from` to `to` is allowed.
   * @throws TripInvalidStateTransitionError if the transition is not valid
   */
  static validateTransition(from: TripStatus, to: TripStatus): void {
    const allowed = TripStateMachine.VALID_TRANSITIONS[from];
    if (!allowed?.has(to)) {
      throw new TripInvalidStateTransitionError(from, to);
    }
  }

  /**
   * Returns all valid next states from a given state.
   */
  static validNextStates(from: TripStatus): TripStatus[] {
    return Array.from(TripStateMachine.VALID_TRANSITIONS[from] ?? []);
  }

  /**
   * Returns true if the given status is a terminal (end) state.
   */
  static isTerminal(status: TripStatus): boolean {
    return (TripStateMachine.VALID_TRANSITIONS[status]?.size ?? 0) === 0;
  }

  /**
   * Returns true if the trip is in any cancellable state (i.e., a cancel transition is valid).
   */
  static isCancellable(status: TripStatus): boolean {
    const nextStates = TripStateMachine.VALID_TRANSITIONS[status];
    return (
      (nextStates?.has('CANCELLED_BY_RIDER') ?? false) ||
      (nextStates?.has('CANCELLED_BY_DRIVER') ?? false)
    );
  }
}
