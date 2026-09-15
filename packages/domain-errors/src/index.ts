// ============================================================
// @fairgo/domain-errors — Domain error taxonomy
// All errors have a machine-readable code and HTTP status hint.
// ============================================================

export abstract class DomainError extends Error {
  abstract readonly code: string;
  abstract readonly httpStatus: number;
  readonly isOperational: boolean = true;

  constructor(
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = this.constructor.name;
    // Maintain proper prototype chain
    Object.setPrototypeOf(this, new.target.prototype);
  }

  toJSON(): Record<string, unknown> {
    return {
      code: this.code,
      message: this.message,
      details: this.details,
    };
  }
}

// ----------------------------------------------------------
// AUTH ERRORS (ERR_AUTH_*)
// ----------------------------------------------------------

export class InvalidTokenError extends DomainError {
  readonly code = 'ERR_AUTH_INVALID_TOKEN';
  readonly httpStatus = 401;
}

export class ExpiredTokenError extends DomainError {
  readonly code = 'ERR_AUTH_TOKEN_EXPIRED';
  readonly httpStatus = 401;
}

export class InsufficientPermissionsError extends DomainError {
  readonly code = 'ERR_AUTH_INSUFFICIENT_PERMISSIONS';
  readonly httpStatus = 403;
}

export class OtpExpiredError extends DomainError {
  readonly code = 'ERR_AUTH_OTP_EXPIRED';
  readonly httpStatus = 400;
}

export class OtpInvalidError extends DomainError {
  readonly code = 'ERR_AUTH_OTP_INVALID';
  readonly httpStatus = 400;
}

export class OtpRateLimitError extends DomainError {
  readonly code = 'ERR_AUTH_OTP_RATE_LIMIT';
  readonly httpStatus = 429;
}

// ----------------------------------------------------------
// RIDER ERRORS (ERR_RIDER_*)
// ----------------------------------------------------------

export class RiderNotFoundError extends DomainError {
  readonly code = 'ERR_RIDER_NOT_FOUND';
  readonly httpStatus = 404;
}

export class RiderSuspendedError extends DomainError {
  readonly code = 'ERR_RIDER_SUSPENDED';
  readonly httpStatus = 403;
}

// ----------------------------------------------------------
// DRIVER ERRORS (ERR_DRIVER_*)
// ----------------------------------------------------------

export class DriverNotFoundError extends DomainError {
  readonly code = 'ERR_DRIVER_NOT_FOUND';
  readonly httpStatus = 404;
}

export class DriverNotOnlineError extends DomainError {
  readonly code = 'ERR_DRIVER_NOT_ONLINE';
  readonly httpStatus = 409;
}

export class DriverAlreadyOnTripError extends DomainError {
  readonly code = 'ERR_DRIVER_ALREADY_ON_TRIP';
  readonly httpStatus = 409;
}

export class DriverKycNotApprovedError extends DomainError {
  readonly code = 'ERR_DRIVER_KYC_NOT_APPROVED';
  readonly httpStatus = 403;
}

export class DriverDocumentExpiredError extends DomainError {
  readonly code = 'ERR_DRIVER_DOCUMENT_EXPIRED';
  readonly httpStatus = 403;
}

// ----------------------------------------------------------
// TRIP ERRORS (ERR_TRIP_*)
// ----------------------------------------------------------

export class TripNotFoundError extends DomainError {
  readonly code = 'ERR_TRIP_NOT_FOUND';
  readonly httpStatus = 404;
}

export class TripInvalidStateTransitionError extends DomainError {
  readonly code = 'ERR_TRIP_INVALID_STATE_TRANSITION';
  readonly httpStatus = 409;

  constructor(
    from: string,
    to: string,
    override readonly details?: unknown,
  ) {
    super(`Cannot transition trip from ${from} to ${to}`);
  }
}

export class TripOtpInvalidError extends DomainError {
  readonly code = 'ERR_TRIP_OTP_INVALID';
  readonly httpStatus = 400;
}

export class NoDriversAvailableError extends DomainError {
  readonly code = 'ERR_TRIP_NO_DRIVERS_AVAILABLE';
  readonly httpStatus = 503;
}

export class TripCancellationWindowExpiredError extends DomainError {
  readonly code = 'ERR_TRIP_CANCELLATION_WINDOW_EXPIRED';
  readonly httpStatus = 409;
}

// ----------------------------------------------------------
// PAYMENT ERRORS (ERR_PAYMENT_*)
// ----------------------------------------------------------

export class PaymentNotFoundError extends DomainError {
  readonly code = 'ERR_PAYMENT_NOT_FOUND';
  readonly httpStatus = 404;
}

export class PaymentAlreadyCapturedError extends DomainError {
  readonly code = 'ERR_PAYMENT_ALREADY_CAPTURED';
  readonly httpStatus = 409;
}

export class PaymentProviderError extends DomainError {
  readonly code = 'ERR_PAYMENT_PROVIDER_FAILURE';
  readonly httpStatus = 502;
}

export class InvalidIdempotencyKeyError extends DomainError {
  readonly code = 'ERR_PAYMENT_IDEMPOTENCY_CONFLICT';
  readonly httpStatus = 409;
}

// ----------------------------------------------------------
// WALLET ERRORS (ERR_WALLET_*)
// ----------------------------------------------------------

export class InsufficientWalletBalanceError extends DomainError {
  readonly code = 'ERR_WALLET_INSUFFICIENT_BALANCE';
  readonly httpStatus = 402;
}

export class WalletNotFoundError extends DomainError {
  readonly code = 'ERR_WALLET_NOT_FOUND';
  readonly httpStatus = 404;
}

export class WalletLockedError extends DomainError {
  readonly code = 'ERR_WALLET_LOCKED';
  readonly httpStatus = 403;
}

export class WalletLimitExceededError extends DomainError {
  readonly code = 'ERR_WALLET_LIMIT_EXCEEDED';
  readonly httpStatus = 400;
}

// ----------------------------------------------------------
// COUPON ERRORS (ERR_COUPON_*)
// ----------------------------------------------------------

export class CouponNotFoundError extends DomainError {
  readonly code = 'ERR_COUPON_NOT_FOUND';
  readonly httpStatus = 404;
}

export class CouponExpiredError extends DomainError {
  readonly code = 'ERR_COUPON_EXPIRED';
  readonly httpStatus = 400;
}

export class CouponUsageLimitError extends DomainError {
  readonly code = 'ERR_COUPON_USAGE_LIMIT_REACHED';
  readonly httpStatus = 400;
}

export class CouponNotApplicableError extends DomainError {
  readonly code = 'ERR_COUPON_NOT_APPLICABLE';
  readonly httpStatus = 400;
}

export class CouponBudgetExhaustedError extends DomainError {
  readonly code = 'ERR_COUPON_BUDGET_EXHAUSTED';
  readonly httpStatus = 400;
}

export class CouponMinimumOrderError extends DomainError {
  readonly code = 'ERR_COUPON_MINIMUM_ORDER_NOT_MET';
  readonly httpStatus = 400;
}

// ----------------------------------------------------------
// VALIDATION ERRORS (ERR_VALIDATION_*)
// ----------------------------------------------------------

export class ValidationError extends DomainError {
  readonly code = 'ERR_VALIDATION';
  readonly httpStatus = 400;
}

export class ResourceNotFoundError extends DomainError {
  readonly code = 'ERR_NOT_FOUND';
  readonly httpStatus = 404;
}

export class ConflictError extends DomainError {
  readonly code = 'ERR_CONFLICT';
  readonly httpStatus = 409;
}

export class RateLimitError extends DomainError {
  readonly code = 'ERR_RATE_LIMIT';
  readonly httpStatus = 429;
}

// ----------------------------------------------------------
// INFRASTRUCTURE ERRORS (ERR_INFRA_*)
// ----------------------------------------------------------

export class ServiceUnavailableError extends DomainError {
  readonly code = 'ERR_SERVICE_UNAVAILABLE';
  readonly httpStatus = 503;
  override readonly isOperational = false;
}

export class ExternalProviderError extends DomainError {
  readonly code = 'ERR_EXTERNAL_PROVIDER';
  readonly httpStatus = 502;
}

// ----------------------------------------------------------
// HELPERS
// ----------------------------------------------------------

export function isDomainError(error: unknown): error is DomainError {
  return error instanceof DomainError;
}

export function isOperationalError(error: unknown): boolean {
  if (error instanceof DomainError) return error.isOperational;
  return false;
}
