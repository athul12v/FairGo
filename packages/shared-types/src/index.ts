// ============================================================
// @fairgo/shared-types — Core enums, entities, DTOs, and interfaces
// All monetary amounts are in paise (integer). Never use float for money.
// ============================================================

// ----------------------------------------------------------
// UTILITY TYPES
// ----------------------------------------------------------

export type UUID = string;
export type Paise = number; // integer, smallest INR unit (1 INR = 100 paise)
export type ISO8601 = string; // "2026-09-15T05:30:00.000Z"
export type PhoneNumber = string; // E.164 format: "+919876543210"
export type Latitude = number; // -90 to 90
export type Longitude = number; // -180 to 180
export type ISOCountryCode = string; // "IN", "US"
export type ISOCurrencyCode = string; // "INR", "USD"
export type LanguageCode = string; // "en", "hi", "ta", "kn"

export interface Coordinates {
  readonly lat: Latitude;
  readonly lon: Longitude;
}

export interface PaginationMeta {
  readonly cursor: string | null;
  readonly hasMore: boolean;
  readonly total?: number;
}

export interface ApiResponse<T> {
  readonly success: true;
  readonly data: T;
  readonly meta?: Record<string, unknown>;
}

export interface ApiError {
  readonly success: false;
  readonly error: {
    readonly code: string;
    readonly message: string;
    readonly details?: unknown[];
    readonly requestId?: string;
  };
}

// ----------------------------------------------------------
// USER & AUTH
// ----------------------------------------------------------

export enum UserRole {
  RIDER = 'RIDER',
  DRIVER = 'DRIVER',
  ADMIN_SUPER = 'ADMIN_SUPER',
  ADMIN_CITY_OPS = 'ADMIN_CITY_OPS',
  ADMIN_FINANCE = 'ADMIN_FINANCE',
  ADMIN_SUPPORT = 'ADMIN_SUPPORT',
  ADMIN_PARTNERSHIPS = 'ADMIN_PARTNERSHIPS',
  CORPORATE_ADMIN = 'CORPORATE_ADMIN',
  CORPORATE_EMPLOYEE = 'CORPORATE_EMPLOYEE',
}

export enum AuthProvider {
  PHONE_OTP = 'PHONE_OTP',
  EMAIL_PASSWORD = 'EMAIL_PASSWORD',
  GOOGLE = 'GOOGLE',
  APPLE = 'APPLE',
}

export interface JwtClaims {
  readonly sub: UUID; // userId from auth service
  readonly role: UserRole;
  readonly riderId?: UUID;
  readonly driverId?: UUID;
  readonly corporateAccountId?: UUID;
  readonly deviceId: string;
  readonly sessionId: UUID;
  readonly iat: number;
  readonly exp: number;
}

// ----------------------------------------------------------
// RIDER
// ----------------------------------------------------------

export interface RiderProfile {
  readonly id: UUID;
  readonly userId: UUID;
  readonly name: string;
  readonly phone: PhoneNumber;
  readonly email?: string;
  readonly profilePhotoUrl?: string;
  readonly preferredLanguage: LanguageCode;
  readonly emergencyContacts: EmergencyContact[];
  readonly savedPlaces: SavedPlace[];
  readonly rating: number; // 1.0–5.0
  readonly totalTrips: number;
  readonly isAccessibilityRequired: boolean;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface EmergencyContact {
  readonly id: UUID;
  readonly name: string;
  readonly phone: PhoneNumber;
  readonly relationship: string;
  readonly notifyOnSOS: boolean;
  readonly notifyLateNight: boolean;
}

export interface SavedPlace {
  readonly id: UUID;
  readonly label: string; // "Home", "Work", custom
  readonly address: string;
  readonly coordinates: Coordinates;
}

// ----------------------------------------------------------
// DRIVER
// ----------------------------------------------------------

export enum DriverStatus {
  OFFLINE = 'OFFLINE',
  ONLINE = 'ONLINE',
  ON_TRIP = 'ON_TRIP',
  ON_BREAK = 'ON_BREAK',
  SUSPENDED = 'SUSPENDED',
}

export enum DriverTier {
  BRONZE = 'BRONZE',
  SILVER = 'SILVER',
  GOLD = 'GOLD',
}

export enum KycStatus {
  PENDING = 'PENDING',
  SUBMITTED = 'SUBMITTED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED',
}

export enum DocumentType {
  DRIVING_LICENSE = 'DRIVING_LICENSE',
  VEHICLE_RC = 'VEHICLE_RC',
  VEHICLE_INSURANCE = 'VEHICLE_INSURANCE',
  VEHICLE_PERMIT = 'VEHICLE_PERMIT',
  POLLUTION_CERTIFICATE = 'POLLUTION_CERTIFICATE',
  PROFILE_PHOTO = 'PROFILE_PHOTO',
  PAN_CARD = 'PAN_CARD',
  AADHAAR = 'AADHAAR',
  BANK_PASSBOOK = 'BANK_PASSBOOK',
}

export interface DriverProfile {
  readonly id: UUID;
  readonly userId: UUID;
  readonly name: string;
  readonly phone: PhoneNumber;
  readonly email?: string;
  readonly profilePhotoUrl?: string;
  readonly status: DriverStatus;
  readonly kycStatus: KycStatus;
  readonly tier: DriverTier;
  readonly rating: number;
  readonly totalTrips: number;
  readonly totalEarningsPaise: Paise;
  readonly preferredLanguage: LanguageCode;
  readonly preferredDestination?: Coordinates;
  readonly preferredDestinationLabel?: string;
  readonly preferredDestinationUsesToday: number;
  readonly isEVDriver: boolean;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface DriverDocument {
  readonly id: UUID;
  readonly driverId: UUID;
  readonly type: DocumentType;
  readonly fileUrl: string; // signed URL from Firebase Cloud Storage
  readonly status: KycStatus;
  readonly expiresAt?: ISO8601;
  readonly reviewNote?: string;
  readonly uploadedAt: ISO8601;
}

// ----------------------------------------------------------
// VEHICLE
// ----------------------------------------------------------

export enum VehicleType {
  BIKE = 'BIKE',
  AUTO = 'AUTO',
  CAB_MINI = 'CAB_MINI',
  CAB_SEDAN = 'CAB_SEDAN',
  CAB_SUV = 'CAB_SUV',
  CAB_ECONOMY = 'CAB_ECONOMY',
  CAB_PREMIUM = 'CAB_PREMIUM',
  PARCEL_BIKE = 'PARCEL_BIKE',
  PARCEL_THREE_WHEELER = 'PARCEL_THREE_WHEELER',
}

export enum VehicleFuelType {
  PETROL = 'PETROL',
  DIESEL = 'DIESEL',
  CNG = 'CNG',
  ELECTRIC = 'ELECTRIC',
  HYBRID = 'HYBRID',
}

export interface Vehicle {
  readonly id: UUID;
  readonly driverId: UUID;
  readonly type: VehicleType;
  readonly make: string;
  readonly model: string;
  readonly year: number;
  readonly color: string;
  readonly licensePlate: string;
  readonly fuelType: VehicleFuelType;
  readonly isEV: boolean;
  readonly seatingCapacity: number;
  readonly isWheelchairAccessible: boolean;
  readonly rcExpiresAt: ISO8601;
  readonly insuranceExpiresAt: ISO8601;
  readonly permitExpiresAt?: ISO8601;
  readonly pollutionCertExpiresAt?: ISO8601;
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

// ----------------------------------------------------------
// TRIP
// ----------------------------------------------------------

export enum TripStatus {
  SEARCHING = 'SEARCHING',
  DRIVER_ASSIGNED = 'DRIVER_ASSIGNED',
  DRIVER_EN_ROUTE = 'DRIVER_EN_ROUTE',
  DRIVER_ARRIVED = 'DRIVER_ARRIVED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED_BY_RIDER = 'CANCELLED_BY_RIDER',
  CANCELLED_BY_DRIVER = 'CANCELLED_BY_DRIVER',
  CANCELLED_BY_SYSTEM = 'CANCELLED_BY_SYSTEM',
  NO_DRIVER_FOUND = 'NO_DRIVER_FOUND',
}

export enum ServiceType {
  BIKE = 'BIKE',
  AUTO = 'AUTO',
  CAB = 'CAB',
  PARCEL = 'PARCEL',
  DRIVER_HIRE = 'DRIVER_HIRE',
}

export enum TripCancellationReason {
  DRIVER_NOT_MOVING = 'DRIVER_NOT_MOVING',
  WRONG_VEHICLE = 'WRONG_VEHICLE',
  PLANS_CHANGED = 'PLANS_CHANGED',
  LONG_WAIT = 'LONG_WAIT',
  BOOKED_ANOTHER = 'BOOKED_ANOTHER',
  EMERGENCY = 'EMERGENCY',
  OTHER = 'OTHER',
  // Driver reasons
  RIDER_NOT_AVAILABLE = 'RIDER_NOT_AVAILABLE',
  INCORRECT_PICKUP = 'INCORRECT_PICKUP',
  RIDER_BEHAVIOUR = 'RIDER_BEHAVIOUR',
  VEHICLE_ISSUE = 'VEHICLE_ISSUE',
}

export interface TripStop {
  readonly order: number; // 0 = pickup, 1+ = waypoints, last = drop
  readonly address: string;
  readonly coordinates: Coordinates;
  readonly arrivalTime?: ISO8601;
}

export interface Trip {
  readonly id: UUID;
  readonly riderId: UUID;
  readonly driverId?: UUID;
  readonly vehicleId?: UUID;
  readonly serviceType: ServiceType;
  readonly vehicleType: VehicleType;
  readonly status: TripStatus;
  readonly stops: TripStop[]; // min 2 (pickup + drop), max 4 (3 stops)
  readonly estimatedFarePaise: Paise;
  readonly actualFarePaise?: Paise;
  readonly distanceMeters?: number;
  readonly durationSeconds?: number;
  readonly surgeMultiplier: number; // e.g., 1.5 = 1.5x surge (stored as fixed-point * 100)
  readonly otpCode: string; // 4-digit OTP for trip start
  readonly cancellationReason?: TripCancellationReason;
  readonly cancellationNote?: string;
  readonly cancellationFeePaise?: Paise;
  readonly shareableToken?: string;
  readonly poolingGroupId?: UUID; // for ride-sharing
  readonly scheduledFor?: ISO8601;
  readonly isPooled: boolean;
  readonly couponId?: UUID;
  readonly discountPaise?: Paise;
  readonly corporateAccountId?: UUID;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
  readonly completedAt?: ISO8601;
}

// ----------------------------------------------------------
// PARCEL
// ----------------------------------------------------------

export enum ParcelSize {
  SMALL = 'SMALL',     // < 1 kg, fits in a bag
  MEDIUM = 'MEDIUM',   // 1–5 kg
  LARGE = 'LARGE',     // 5–20 kg
  EXTRA_LARGE = 'EXTRA_LARGE', // 20–50 kg
}

export enum ParcelStatus {
  CREATED = 'CREATED',
  PICKUP_AWAITING = 'PICKUP_AWAITING',
  PICKED_UP = 'PICKED_UP',
  IN_TRANSIT = 'IN_TRANSIT',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED',
  RETURN_INITIATED = 'RETURN_INITIATED',
  RETURNED = 'RETURNED',
}

export interface ParcelDelivery {
  readonly id: UUID;
  readonly riderId: UUID;
  readonly driverId?: UUID;
  readonly status: ParcelStatus;
  readonly size: ParcelSize;
  readonly weightGrams: number;
  readonly description: string;
  readonly senderName: string;
  readonly senderPhone: PhoneNumber;
  readonly receiverName: string;
  readonly receiverPhone: PhoneNumber;
  readonly pickupAddress: string;
  readonly pickupCoordinates: Coordinates;
  readonly dropAddress: string;
  readonly dropCoordinates: Coordinates;
  readonly pickupOtp: string;
  readonly dropOtp: string;
  readonly estimatedFarePaise: Paise;
  readonly actualFarePaise?: Paise;
  readonly pickedUpAt?: ISO8601;
  readonly deliveredAt?: ISO8601;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// PAYMENT
// ----------------------------------------------------------

export enum PaymentStatus {
  PENDING = 'PENDING',
  AUTHORIZED = 'AUTHORIZED',
  CAPTURED = 'CAPTURED',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
  PARTIALLY_REFUNDED = 'PARTIALLY_REFUNDED',
  CANCELLED = 'CANCELLED',
}

export enum PaymentMethod {
  UPI = 'UPI',
  CREDIT_CARD = 'CREDIT_CARD',
  DEBIT_CARD = 'DEBIT_CARD',
  NET_BANKING = 'NET_BANKING',
  WALLET = 'WALLET',     // FairGo wallet
  CASH = 'CASH',
  CORPORATE = 'CORPORATE',
}

export enum PaymentProvider {
  RAZORPAY = 'RAZORPAY',
  STRIPE = 'STRIPE',
  PAYU = 'PAYU',
  CASH = 'CASH',
  INTERNAL_WALLET = 'INTERNAL_WALLET',
}

export interface Payment {
  readonly id: UUID;
  readonly tripId?: UUID;
  readonly parcelId?: UUID;
  readonly riderId: UUID;
  readonly amountPaise: Paise;
  readonly currency: ISOCurrencyCode;
  readonly method: PaymentMethod;
  readonly provider: PaymentProvider;
  readonly providerPaymentId?: string;
  readonly providerOrderId?: string;
  readonly status: PaymentStatus;
  readonly idempotencyKey: string;
  readonly capturedAt?: ISO8601;
  readonly refundedAmountPaise?: Paise;
  readonly metadata: Record<string, string>;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

// ----------------------------------------------------------
// WALLET & LEDGER
// ----------------------------------------------------------

export enum WalletType {
  RIDER = 'RIDER',
  DRIVER = 'DRIVER',
  PLATFORM_REVENUE = 'PLATFORM_REVENUE',
  PLATFORM_INCENTIVES = 'PLATFORM_INCENTIVES',
  TRIP_ESCROW = 'TRIP_ESCROW',
  CASHBACK_POOL = 'CASHBACK_POOL',
}

export enum LedgerEntryType {
  DEBIT = 'DEBIT',
  CREDIT = 'CREDIT',
}

export interface WalletAccount {
  readonly id: UUID;
  readonly ownerId: UUID;
  readonly walletType: WalletType;
  readonly balancePaise: Paise; // derived from ledger, refreshed as materialized view
  readonly currency: ISOCurrencyCode;
  readonly isLocked: boolean;
  readonly kycTier: 'NONE' | 'MIN' | 'FULL';
  readonly monthlyLoadLimitPaise: Paise; // RBI PPI limits
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface LedgerEntry {
  readonly id: UUID;
  readonly walletId: UUID;
  readonly entryType: LedgerEntryType;
  readonly amountPaise: Paise;
  readonly balanceAfterPaise: Paise;
  readonly referenceType: string; // "TRIP", "TOPUP", "REFUND", "CASHBACK", "PAYOUT", etc.
  readonly referenceId: UUID;
  readonly description: string;
  readonly createdAt: ISO8601; // immutable — never updated
}

// ----------------------------------------------------------
// COUPON & LOYALTY
// ----------------------------------------------------------

export enum CouponType {
  FLAT_OFF = 'FLAT_OFF',
  PERCENTAGE_OFF = 'PERCENTAGE_OFF',
  FREE_RIDE = 'FREE_RIDE',
  CASHBACK = 'CASHBACK',
}

export enum CouponApplicability {
  ALL = 'ALL',
  BIKE = 'BIKE',
  AUTO = 'AUTO',
  CAB = 'CAB',
  PARCEL = 'PARCEL',
  FIRST_RIDE = 'FIRST_RIDE',
}

export interface Coupon {
  readonly id: UUID;
  readonly code: string;
  readonly type: CouponType;
  readonly applicability: CouponApplicability;
  readonly discountPaise?: Paise;
  readonly discountPercent?: number;
  readonly maxDiscountPaise?: Paise;
  readonly minOrderPaise: Paise;
  readonly totalBudgetPaise: Paise;
  readonly usedBudgetPaise: Paise;
  readonly maxUsesPerUser: number;
  readonly totalMaxUses: number;
  readonly totalUses: number;
  readonly validFrom: ISO8601;
  readonly validUntil: ISO8601;
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
}

export enum LoyaltyTier {
  BRONZE = 'BRONZE',
  SILVER = 'SILVER',
  GOLD = 'GOLD',
  PLATINUM = 'PLATINUM',
}

export interface LoyaltyAccount {
  readonly id: UUID;
  readonly riderId: UUID;
  readonly tier: LoyaltyTier;
  readonly pointsBalance: number;
  readonly lifetimePoints: number;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

// ----------------------------------------------------------
// SAFETY / SOS
// ----------------------------------------------------------

export enum SosStatus {
  TRIGGERED = 'TRIGGERED',
  ACKNOWLEDGED = 'ACKNOWLEDGED',
  ESCALATED_CONTROL_ROOM = 'ESCALATED_CONTROL_ROOM',
  ESCALATED_LOCAL_AUTHORITY = 'ESCALATED_LOCAL_AUTHORITY',
  RESOLVED = 'RESOLVED',
  FALSE_ALARM = 'FALSE_ALARM',
}

export enum SosInitiator {
  RIDER = 'RIDER',
  DRIVER = 'DRIVER',
  SYSTEM = 'SYSTEM', // auto-triggered by anomaly detection
}

export interface SosIncident {
  readonly id: UUID;
  readonly tripId?: UUID;
  readonly initiator: SosInitiator;
  readonly initiatorId: UUID;
  readonly status: SosStatus;
  readonly coordinates?: Coordinates;
  readonly emergencyContactsNotified: UUID[];
  readonly controlRoomTicketId?: string;
  readonly localAuthorityTicketId?: string;
  readonly audioRecordingUrl?: string; // only stored with explicit consent
  readonly resolvedAt?: ISO8601;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

// ----------------------------------------------------------
// CORPORATE
// ----------------------------------------------------------

export interface CorporateAccount {
  readonly id: UUID;
  readonly companyName: string;
  readonly gstIn?: string;
  readonly creditLimitPaise: Paise;
  readonly usedCreditPaise: Paise;
  readonly billingCycleDay: number; // 1–28
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface CorporateEmployee {
  readonly id: UUID;
  readonly corporateAccountId: UUID;
  readonly riderId?: UUID;
  readonly email: string;
  readonly name: string;
  readonly isAdmin: boolean;
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// INSURANCE
// ----------------------------------------------------------

export enum InsurancePolicyType {
  ACCIDENT_COVER = 'ACCIDENT_COVER',
  MEDICAL_COVER = 'MEDICAL_COVER',
  PER_TRIP = 'PER_TRIP',
  SUBSCRIPTION_MONTHLY = 'SUBSCRIPTION_MONTHLY',
  SUBSCRIPTION_ANNUAL = 'SUBSCRIPTION_ANNUAL',
}

export enum InsurancePolicyStatus {
  ACTIVE = 'ACTIVE',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED',
  CLAIMED = 'CLAIMED',
}

export enum InsuranceClaimStatus {
  SUBMITTED = 'SUBMITTED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  SETTLED = 'SETTLED',
}

export interface InsurancePolicy {
  readonly id: UUID;
  readonly holderId: UUID; // riderId or driverId
  readonly holderType: 'RIDER' | 'DRIVER';
  readonly providerId: UUID;
  readonly policyType: InsurancePolicyType;
  readonly policyNumber: string;
  readonly coverageAmountPaise: Paise;
  readonly premiumPaise: Paise;
  readonly status: InsurancePolicyStatus;
  readonly tripId?: UUID; // for per-trip policies
  readonly startsAt: ISO8601;
  readonly expiresAt: ISO8601;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// SUPPORT
// ----------------------------------------------------------

export enum SupportTicketStatus {
  OPEN = 'OPEN',
  ASSIGNED = 'ASSIGNED',
  IN_PROGRESS = 'IN_PROGRESS',
  WAITING_CUSTOMER = 'WAITING_CUSTOMER',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
}

export enum SupportTicketCategory {
  TRIP_ISSUE = 'TRIP_ISSUE',
  PAYMENT_ISSUE = 'PAYMENT_ISSUE',
  DRIVER_BEHAVIOUR = 'DRIVER_BEHAVIOUR',
  LOST_ITEM = 'LOST_ITEM',
  SAFETY = 'SAFETY',
  ACCOUNT = 'ACCOUNT',
  TECHNICAL = 'TECHNICAL',
  OTHER = 'OTHER',
}

export enum SupportChannel {
  CALL = 'CALL',
  EMAIL = 'EMAIL',
  CHAT = 'CHAT',
}

export enum SupportPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export interface SupportAttachment {
  readonly url: string;
  readonly fileName: string;
  readonly fileSize: number;
  readonly mimeType: string;
}

export interface SupportCase {
  readonly id: UUID;
  readonly ticketNumber: string; // human-readable: FG-2026-10482
  readonly userId: UUID;
  readonly userRole: 'RIDER' | 'DRIVER';
  readonly tripId?: UUID | undefined;
  readonly channel: SupportChannel;
  readonly category: SupportTicketCategory;
  readonly subject: string;
  readonly description: string;
  readonly status: SupportTicketStatus;
  readonly priority: SupportPriority;
  readonly assignedAgentId?: UUID | undefined;
  readonly internalNotes?: string | undefined;
  readonly attachments: SupportAttachment[];
  readonly csatRating?: number | undefined; // 1-5
  readonly csatComment?: string | undefined;
  readonly resolvedAt?: ISO8601 | undefined;
  readonly closedAt?: ISO8601 | undefined;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface SupportTicket extends SupportCase {
  // Backwards compatibility alias
  readonly reporterId: UUID;
  readonly reporterType: 'RIDER' | 'DRIVER';
  readonly assignedTo?: UUID | undefined;
}

export enum ConversationStatus {
  WAITING = 'WAITING',
  ACTIVE = 'ACTIVE',
  ENDED = 'ENDED',
}

export interface SupportConversation {
  readonly id: UUID;
  readonly caseId: UUID;
  readonly userId: UUID;
  readonly agentId?: UUID | undefined;
  readonly status: ConversationStatus;
  readonly webrtcSessionId?: string | undefined;
  readonly agentName?: string | undefined;
  readonly startedAt: ISO8601;
  readonly endedAt?: ISO8601 | undefined;
  readonly createdAt: ISO8601;
}

export enum MessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  FILE = 'FILE',
  SYSTEM = 'SYSTEM',
}

export enum SenderRole {
  CUSTOMER = 'CUSTOMER',
  AGENT = 'AGENT',
  SYSTEM = 'SYSTEM',
}

export enum DeliveryStatus {
  SENT = 'SENT',
  DELIVERED = 'DELIVERED',
  READ = 'READ',
}

export interface SupportMessage {
  readonly id: UUID;
  readonly conversationId: UUID;
  readonly senderId: UUID;
  readonly senderRole: SenderRole;
  readonly type: MessageType;
  readonly content: string;
  readonly attachmentUrl?: string | undefined;
  readonly attachmentMetadata?: Record<string, unknown> | undefined;
  readonly deliveryStatus: DeliveryStatus;
  readonly createdAt: ISO8601;
}

export interface SupportCallbackRequest {
  readonly id: UUID;
  readonly caseId: UUID;
  readonly userId: UUID;
  readonly phoneNumber: PhoneNumber;
  readonly preferredTimeWindow: string;
  readonly status: 'PENDING' | 'SCHEDULED' | 'COMPLETED' | 'CANCELLED';
  readonly assignedAgentId?: UUID | undefined;
  readonly notes?: string | undefined;
  readonly createdAt: ISO8601;
  readonly updatedAt: ISO8601;
}

export interface SupportFaqItem {
  readonly id: UUID;
  readonly category: SupportTicketCategory;
  readonly question: string;
  readonly answer: string;
  readonly sortOrder: number;
  readonly isActive: boolean;
}

export interface SupportAvailability {
  readonly chat: {
    readonly isAvailable: boolean;
    readonly activeAgentsCount: number;
    readonly queueLength: number;
    readonly estimatedWaitSeconds: number;
  };
  readonly call: {
    readonly isAvailable: boolean;
    readonly phoneNumber: string;
    readonly operatingHours: string;
    readonly callbackAvailable: boolean;
  };
  readonly email: {
    readonly isAvailable: true;
    readonly responseTimeWindow: string;
  };
}

export interface WebRtcSignalPayload {
  readonly conversationId: UUID;
  readonly senderId: UUID;
  readonly targetId?: UUID;
  readonly type: 'offer' | 'answer' | 'candidate';
  readonly sdp?: string;
  readonly candidate?: {
    readonly candidate: string;
    readonly sdpMid?: string | null;
    readonly sdpMLineIndex?: number | null;
  };
}

// ----------------------------------------------------------
// RATING
// ----------------------------------------------------------

export interface Rating {
  readonly id: UUID;
  readonly tripId: UUID;
  readonly raterId: UUID;
  readonly raterType: 'RIDER' | 'DRIVER';
  readonly rateeId: UUID;
  readonly score: number; // 1–5
  readonly comment?: string;
  readonly tipPaise?: Paise;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// ZONE / PRICING
// ----------------------------------------------------------

export interface Zone {
  readonly id: UUID;
  readonly cityId: UUID;
  readonly name: string;
  readonly geojson: string; // GeoJSON Polygon string
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
}

export interface PricingRule {
  readonly id: UUID;
  readonly zoneId?: UUID; // null = global default
  readonly vehicleType: VehicleType;
  readonly baseFarePaise: Paise;
  readonly perKmPaise: Paise;
  readonly perMinutePaise: Paise;
  readonly minimumFarePaise: Paise;
  readonly cancellationFeePaise: Paise;
  readonly cancellationFreeWindowSeconds: number;
  readonly validFrom: ISO8601;
  readonly validUntil?: ISO8601;
  readonly isActive: boolean;
  readonly createdAt: ISO8601;
}

export interface SurgeRule {
  readonly id: UUID;
  readonly zoneId: UUID;
  readonly vehicleType?: VehicleType; // null = all types
  readonly multiplierBps: number; // basis points: 150 = 1.5x surge
  readonly triggerDemandSupplyRatio: number; // e.g., 2.0 = 2:1 demand:supply
  readonly maxMultiplierBps: number; // cap: 300 = 3x max
  readonly isActive: boolean;
}

// ----------------------------------------------------------
// NOTIFICATIONS
// ----------------------------------------------------------

export enum NotificationChannel {
  PUSH = 'PUSH',
  SMS = 'SMS',
  EMAIL = 'EMAIL',
  IN_APP = 'IN_APP',
  WHATSAPP = 'WHATSAPP',
}

export enum NotificationStatus {
  PENDING = 'PENDING',
  SENT = 'SENT',
  DELIVERED = 'DELIVERED',
  FAILED = 'FAILED',
  READ = 'READ',
}

export interface Notification {
  readonly id: UUID;
  readonly recipientId: UUID;
  readonly recipientType: 'RIDER' | 'DRIVER' | 'ADMIN';
  readonly channel: NotificationChannel;
  readonly title: string;
  readonly body: string;
  readonly data?: Record<string, string>;
  readonly status: NotificationStatus;
  readonly referenceType?: string;
  readonly referenceId?: UUID;
  readonly sentAt?: ISO8601;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// AUDIT LOG
// ----------------------------------------------------------

export interface AuditLog {
  readonly id: UUID;
  readonly actorId: UUID;
  readonly actorRole: UserRole;
  readonly action: string; // e.g., "driver.kyc.approved"
  readonly resourceType: string;
  readonly resourceId: UUID;
  readonly changes?: Record<string, unknown>;
  readonly ipAddress?: string;
  readonly userAgent?: string;
  readonly requestId: string;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// DRIVER INCENTIVE / PAYOUT
// ----------------------------------------------------------

export enum IncentiveType {
  TRIP_BONUS = 'TRIP_BONUS',
  PEAK_HOUR_BONUS = 'PEAK_HOUR_BONUS',
  REFERRAL_BONUS = 'REFERRAL_BONUS',
  WEEKLY_GUARANTEE = 'WEEKLY_GUARANTEE',
  NEW_DRIVER_BONUS = 'NEW_DRIVER_BONUS',
  FESTIVAL_BONUS = 'FESTIVAL_BONUS',
}

export enum PayoutStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

export interface DriverIncentive {
  readonly id: UUID;
  readonly driverId: UUID;
  readonly type: IncentiveType;
  readonly amountPaise: Paise;
  readonly description: string;
  readonly isEarned: boolean;
  readonly earnedAt?: ISO8601;
  readonly expiresAt?: ISO8601;
  readonly createdAt: ISO8601;
}

export interface Payout {
  readonly id: UUID;
  readonly driverId: UUID;
  readonly walletId: UUID;
  readonly amountPaise: Paise;
  readonly status: PayoutStatus;
  readonly provider: PaymentProvider;
  readonly providerPayoutId?: string;
  readonly bankAccountLast4?: string;
  readonly idempotencyKey: string;
  readonly initiatedAt: ISO8601;
  readonly completedAt?: ISO8601;
  readonly failureReason?: string;
  readonly createdAt: ISO8601;
}

// ----------------------------------------------------------
// FARE ESTIMATE
// ----------------------------------------------------------

export interface FareEstimate {
  readonly vehicleType: VehicleType;
  readonly estimatedFarePaise: Paise;
  readonly minimumFarePaise: Paise;
  readonly maximumFarePaise: Paise;
  readonly distanceMeters: number;
  readonly durationSeconds: number;
  readonly surgeMultiplierBps: number; // basis points, 100 = 1.0x
  readonly breakdownPaise: {
    readonly baseFare: Paise;
    readonly distanceFare: Paise;
    readonly timeFare: Paise;
    readonly surge: Paise;
    readonly taxes: Paise;
  };
  readonly etaSeconds: number; // eta for nearest driver
  readonly nearbyDriverCount: number;
  readonly currency: ISOCurrencyCode;
}

// ----------------------------------------------------------
// LOCATION
// ----------------------------------------------------------

export interface DriverLocationUpdate {
  readonly driverId: UUID;
  readonly lat: Latitude;
  readonly lon: Longitude;
  readonly speed: number; // km/h
  readonly bearing: number; // 0–360
  readonly accuracy: number; // meters
  readonly timestamp: number; // unix ms
  readonly batteryLevel?: number; // 0–100
  readonly tripId?: UUID;
}

export interface DriverLocationSnapshot {
  readonly driverId: UUID;
  readonly coordinates: Coordinates;
  readonly bearing: number;
  readonly speed: number;
  readonly status: DriverStatus;
  readonly vehicleType: VehicleType;
  readonly isEV: boolean;
  readonly isWheelchairAccessible: boolean;
  readonly lastSeenAt: ISO8601;
}
