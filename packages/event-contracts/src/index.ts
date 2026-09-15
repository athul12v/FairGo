// ============================================================
// @fairgo/event-contracts — Versioned Kafka event schemas
// All events follow the EventEnvelope structure.
// Topics: fairgo.<domain>.<event-name>
// ============================================================

import type { UUID, ISO8601, Coordinates, TripStatus, PaymentStatus, ParcelStatus, SosStatus } from '@fairgo/shared-types';

// ----------------------------------------------------------
// BASE EVENT ENVELOPE
// ----------------------------------------------------------

export interface EventEnvelope<T = unknown> {
  readonly eventId: UUID;          // unique per event, used for idempotency
  readonly eventType: string;      // e.g., "trip.completed"
  readonly version: string;        // e.g., "v1"
  readonly occurredAt: ISO8601;
  readonly correlationId: UUID;    // traces across service boundaries
  readonly causationId?: UUID;     // eventId of the event that caused this one
  readonly payload: T;
  readonly metadata: EventMetadata;
}

export interface EventMetadata {
  readonly source: string;         // service name: "trip-service"
  readonly environment: string;    // "production", "staging", "development"
  readonly schemaVersion: string;  // matches version field
}

// ----------------------------------------------------------
// TOPIC NAMES
// ----------------------------------------------------------

export const TOPICS = {
  // Booking lifecycle
  BOOKING_CREATED: 'fairgo.booking.created',
  FARE_QUOTED: 'fairgo.fare.quoted',

  // Driver matching
  DRIVER_SEARCH_STARTED: 'fairgo.driver.search-started',
  DRIVER_ASSIGNED: 'fairgo.driver.assigned',
  DRIVER_ARRIVED: 'fairgo.driver.arrived',
  DRIVER_SEARCH_FAILED: 'fairgo.driver.search-failed',

  // Trip lifecycle
  TRIP_STARTED: 'fairgo.trip.started',
  TRIP_COMPLETED: 'fairgo.trip.completed',
  TRIP_CANCELLED: 'fairgo.trip.cancelled',

  // Location
  DRIVER_MOVED: 'fairgo.location.driver-moved',

  // Payment
  PAYMENT_AUTHORIZED: 'fairgo.payment.authorized',
  PAYMENT_CAPTURED: 'fairgo.payment.captured',
  PAYMENT_FAILED: 'fairgo.payment.failed',
  REFUND_CREATED: 'fairgo.payment.refund-created',
  REFUND_PROCESSED: 'fairgo.payment.refund-processed',

  // Wallet
  WALLET_CREDITED: 'fairgo.wallet.credited',
  WALLET_DEBITED: 'fairgo.wallet.debited',
  CASHBACK_EARNED: 'fairgo.wallet.cashback-earned',
  PAYOUT_INITIATED: 'fairgo.wallet.payout-initiated',
  PAYOUT_COMPLETED: 'fairgo.wallet.payout-completed',

  // Parcel
  PARCEL_CREATED: 'fairgo.parcel.created',
  PARCEL_PICKED_UP: 'fairgo.parcel.picked-up',
  PARCEL_DELIVERED: 'fairgo.parcel.delivered',
  PARCEL_CANCELLED: 'fairgo.parcel.cancelled',

  // Safety
  SOS_TRIGGERED: 'fairgo.safety.sos-triggered',
  SOS_ESCALATED: 'fairgo.safety.sos-escalated',
  SOS_RESOLVED: 'fairgo.safety.sos-resolved',

  // Insurance
  INSURANCE_PURCHASED: 'fairgo.insurance.purchased',
  INSURANCE_CLAIM_CREATED: 'fairgo.insurance.claim-created',
  INSURANCE_CLAIM_SETTLED: 'fairgo.insurance.claim-settled',

  // Corporate
  CORPORATE_TRIP_CREATED: 'fairgo.corporate.trip-created',
  CORPORATE_INVOICE_GENERATED: 'fairgo.corporate.invoice-generated',

  // Driver
  DRIVER_REGISTERED: 'fairgo.driver.registered',
  DRIVER_KYC_SUBMITTED: 'fairgo.driver.kyc-submitted',
  DRIVER_KYC_APPROVED: 'fairgo.driver.kyc-approved',
  DRIVER_KYC_REJECTED: 'fairgo.driver.kyc-rejected',
  DRIVER_WENT_ONLINE: 'fairgo.driver.went-online',
  DRIVER_WENT_OFFLINE: 'fairgo.driver.went-offline',

  // Coupon / Loyalty
  COUPON_APPLIED: 'fairgo.coupon.applied',
  LOYALTY_POINTS_EARNED: 'fairgo.loyalty.points-earned',
  LOYALTY_POINTS_REDEEMED: 'fairgo.loyalty.points-redeemed',
  LOYALTY_TIER_UPGRADED: 'fairgo.loyalty.tier-upgraded',

  // Dead-letter suffixes (append to original topic)
  DLQ_SUFFIX: '.dlq',
} as const;

// ----------------------------------------------------------
// EVENT PAYLOAD TYPES — v1
// ----------------------------------------------------------

// BOOKING_CREATED
export interface BookingCreatedPayloadV1 {
  readonly tripId: UUID;
  readonly riderId: UUID;
  readonly serviceType: string;
  readonly vehicleType: string;
  readonly pickupCoordinates: Coordinates;
  readonly dropCoordinates: Coordinates;
  readonly estimatedFarePaise: number;
  readonly couponId?: UUID;
  readonly scheduledFor?: ISO8601;
  readonly isPooled: boolean;
}

export type BookingCreatedEventV1 = EventEnvelope<BookingCreatedPayloadV1>;

// DRIVER_ASSIGNED
export interface DriverAssignedPayloadV1 {
  readonly tripId: UUID;
  readonly driverId: UUID;
  readonly vehicleId: UUID;
  readonly riderId: UUID;
  readonly etaSeconds: number;
  readonly driverCoordinates: Coordinates;
}

export type DriverAssignedEventV1 = EventEnvelope<DriverAssignedPayloadV1>;

// DRIVER_ARRIVED
export interface DriverArrivedPayloadV1 {
  readonly tripId: UUID;
  readonly driverId: UUID;
  readonly riderId: UUID;
  readonly arrivedAt: ISO8601;
}

export type DriverArrivedEventV1 = EventEnvelope<DriverArrivedPayloadV1>;

// TRIP_STARTED
export interface TripStartedPayloadV1 {
  readonly tripId: UUID;
  readonly driverId: UUID;
  readonly riderId: UUID;
  readonly startedAt: ISO8601;
  readonly startCoordinates: Coordinates;
}

export type TripStartedEventV1 = EventEnvelope<TripStartedPayloadV1>;

// TRIP_COMPLETED
export interface TripCompletedPayloadV1 {
  readonly tripId: UUID;
  readonly driverId: UUID;
  readonly riderId: UUID;
  readonly completedAt: ISO8601;
  readonly actualFarePaise: number;
  readonly distanceMeters: number;
  readonly durationSeconds: number;
  readonly paymentId: UUID;
  readonly corporateAccountId?: UUID;
}

export type TripCompletedEventV1 = EventEnvelope<TripCompletedPayloadV1>;

// TRIP_CANCELLED
export interface TripCancelledPayloadV1 {
  readonly tripId: UUID;
  readonly driverId?: UUID;
  readonly riderId: UUID;
  readonly cancelledBy: 'RIDER' | 'DRIVER' | 'SYSTEM';
  readonly reason: string;
  readonly cancellationFeePaise: number;
  readonly status: TripStatus;
}

export type TripCancelledEventV1 = EventEnvelope<TripCancelledPayloadV1>;

// PAYMENT_CAPTURED
export interface PaymentCapturedPayloadV1 {
  readonly paymentId: UUID;
  readonly tripId?: UUID;
  readonly parcelId?: UUID;
  readonly riderId: UUID;
  readonly amountPaise: number;
  readonly method: string;
  readonly provider: string;
  readonly capturedAt: ISO8601;
}

export type PaymentCapturedEventV1 = EventEnvelope<PaymentCapturedPayloadV1>;

// PAYMENT_FAILED
export interface PaymentFailedPayloadV1 {
  readonly paymentId: UUID;
  readonly tripId?: UUID;
  readonly riderId: UUID;
  readonly amountPaise: number;
  readonly reason: string;
  readonly provider: string;
}

export type PaymentFailedEventV1 = EventEnvelope<PaymentFailedPayloadV1>;

// REFUND_CREATED
export interface RefundCreatedPayloadV1 {
  readonly refundId: UUID;
  readonly paymentId: UUID;
  readonly tripId?: UUID;
  readonly riderId: UUID;
  readonly amountPaise: number;
  readonly reason: string;
}

export type RefundCreatedEventV1 = EventEnvelope<RefundCreatedPayloadV1>;

// WALLET_CREDITED
export interface WalletCreditedPayloadV1 {
  readonly ledgerEntryId: UUID;
  readonly walletId: UUID;
  readonly ownerId: UUID;
  readonly amountPaise: number;
  readonly balanceAfterPaise: number;
  readonly referenceType: string;
  readonly referenceId: UUID;
  readonly description: string;
}

export type WalletCreditedEventV1 = EventEnvelope<WalletCreditedPayloadV1>;

// WALLET_DEBITED
export interface WalletDebitedPayloadV1 {
  readonly ledgerEntryId: UUID;
  readonly walletId: UUID;
  readonly ownerId: UUID;
  readonly amountPaise: number;
  readonly balanceAfterPaise: number;
  readonly referenceType: string;
  readonly referenceId: UUID;
  readonly description: string;
}

export type WalletDebitedEventV1 = EventEnvelope<WalletDebitedPayloadV1>;

// CASHBACK_EARNED
export interface CashbackEarnedPayloadV1 {
  readonly ledgerEntryId: UUID;
  readonly riderId: UUID;
  readonly walletId: UUID;
  readonly amountPaise: number;
  readonly tripId?: UUID;
  readonly couponId?: UUID;
  readonly earnedAt: ISO8601;
}

export type CashbackEarnedEventV1 = EventEnvelope<CashbackEarnedPayloadV1>;

// PARCEL_CREATED
export interface ParcelCreatedPayloadV1 {
  readonly parcelId: UUID;
  readonly riderId: UUID;
  readonly status: ParcelStatus;
  readonly pickupCoordinates: Coordinates;
  readonly dropCoordinates: Coordinates;
  readonly estimatedFarePaise: number;
}

export type ParcelCreatedEventV1 = EventEnvelope<ParcelCreatedPayloadV1>;

// PARCEL_PICKED_UP
export interface ParcelPickedUpPayloadV1 {
  readonly parcelId: UUID;
  readonly driverId: UUID;
  readonly pickedUpAt: ISO8601;
  readonly coordinates: Coordinates;
}

export type ParcelPickedUpEventV1 = EventEnvelope<ParcelPickedUpPayloadV1>;

// PARCEL_DELIVERED
export interface ParcelDeliveredPayloadV1 {
  readonly parcelId: UUID;
  readonly driverId: UUID;
  readonly deliveredAt: ISO8601;
  readonly actualFarePaise: number;
}

export type ParcelDeliveredEventV1 = EventEnvelope<ParcelDeliveredPayloadV1>;

// SOS_TRIGGERED
export interface SosTriggeredPayloadV1 {
  readonly incidentId: UUID;
  readonly tripId?: UUID;
  readonly initiator: 'RIDER' | 'DRIVER';
  readonly initiatorId: UUID;
  readonly coordinates?: Coordinates;
  readonly triggeredAt: ISO8601;
}

export type SosTriggeredEventV1 = EventEnvelope<SosTriggeredPayloadV1>;

// SOS_ESCALATED
export interface SosEscalatedPayloadV1 {
  readonly incidentId: UUID;
  readonly escalationLevel: 'CONTROL_ROOM' | 'LOCAL_AUTHORITY';
  readonly ticketId: string;
  readonly escalatedAt: ISO8601;
}

export type SosEscalatedEventV1 = EventEnvelope<SosEscalatedPayloadV1>;

// SOS_RESOLVED
export interface SosResolvedPayloadV1 {
  readonly incidentId: UUID;
  readonly status: SosStatus;
  readonly resolvedAt: ISO8601;
  readonly resolvedBy: UUID;
}

export type SosResolvedEventV1 = EventEnvelope<SosResolvedPayloadV1>;

// INSURANCE_PURCHASED
export interface InsurancePurchasedPayloadV1 {
  readonly policyId: UUID;
  readonly holderId: UUID;
  readonly holderType: 'RIDER' | 'DRIVER';
  readonly providerId: UUID;
  readonly policyType: string;
  readonly premiumPaise: number;
  readonly coverageAmountPaise: number;
  readonly expiresAt: ISO8601;
}

export type InsurancePurchasedEventV1 = EventEnvelope<InsurancePurchasedPayloadV1>;

// DRIVER_KYC_APPROVED
export interface DriverKycApprovedPayloadV1 {
  readonly driverId: UUID;
  readonly approvedBy: UUID;
  readonly approvedAt: ISO8601;
}

export type DriverKycApprovedEventV1 = EventEnvelope<DriverKycApprovedPayloadV1>;

// CORPORATE_TRIP_CREATED
export interface CorporateTripCreatedPayloadV1 {
  readonly tripId: UUID;
  readonly corporateAccountId: UUID;
  readonly employeeId: UUID;
  readonly riderId: UUID;
  readonly estimatedFarePaise: number;
}

export type CorporateTripCreatedEventV1 = EventEnvelope<CorporateTripCreatedPayloadV1>;

// CORPORATE_INVOICE_GENERATED
export interface CorporateInvoiceGeneratedPayloadV1 {
  readonly invoiceId: UUID;
  readonly corporateAccountId: UUID;
  readonly periodStart: ISO8601;
  readonly periodEnd: ISO8601;
  readonly totalAmountPaise: number;
  readonly tripCount: number;
  readonly pdfUrl: string;
}

export type CorporateInvoiceGeneratedEventV1 = EventEnvelope<CorporateInvoiceGeneratedPayloadV1>;

// ----------------------------------------------------------
// HELPERS
// ----------------------------------------------------------

import { randomUUID } from 'crypto';

export function createEvent<T>(
  eventType: string,
  version: 'v1',
  payload: T,
  options: {
    correlationId?: UUID;
    causationId?: UUID;
    source: string;
  },
): EventEnvelope<T> {
  const base = {
    eventId: randomUUID(),
    eventType,
    version,
    occurredAt: new Date().toISOString(),
    correlationId: options.correlationId ?? randomUUID(),
    payload,
    metadata: {
      source: options.source,
      environment: (process.env['NODE_ENV'] as string | undefined) ?? 'development',
      schemaVersion: version,
    },
  } satisfies Omit<EventEnvelope<T>, 'causationId'>;

  // exactOptionalPropertyTypes: only include causationId when it has a value
  if (options.causationId !== undefined) {
    return { ...base, causationId: options.causationId };
  }
  return base;
}
