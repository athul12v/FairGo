import crypto from 'crypto';
import { hash, compare } from 'bcryptjs';
import type { Pool } from 'pg';
import { createLogger } from '@fairgo/logger';
import {
  OtpExpiredError,
  OtpInvalidError,
  OtpRateLimitError,
} from '@fairgo/domain-errors';

const log = createLogger('auth-service:otp');

// OTP config
const OTP_LENGTH = 6;
const OTP_TTL_SECONDS = 300; // 5 minutes
const OTP_MAX_ATTEMPTS = 3;
const OTP_RATE_LIMIT_WINDOW_SECONDS = 600; // 10 minutes
const OTP_RATE_LIMIT_MAX_SENDS = 5;

// INTEGRATION_BOUNDARY: SMS provider
// In production: replace LocalSmsAdapter with TwilioAdapter or AwsSnsAdapter
export interface SmsProvider {
  sendOtp(phone: string, otp: string): Promise<void>;
}

export class LocalSmsAdapter implements SmsProvider {
  async sendOtp(_phone: string, otp: string): Promise<void> {
    // INTEGRATION_BOUNDARY: LocalSmsAdapter logs OTP to console — NOT for production
    // In production: configure TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER
    log.info('DEV: OTP generated (console-only — configure SMS provider for production)', {
      otp: process.env['NODE_ENV'] === 'development' ? otp : '[REDACTED]',
    });
  }
}

// Redis client interface — avoids circular type dependency
export interface RedisClientLike {
  incr(key: string): Promise<number>;
  expire(key: string, seconds: number): Promise<boolean>;
  get(key: string): Promise<string | null>;
  setEx(key: string, seconds: number, value: string): Promise<string>;
  del(key: string): Promise<number>;
  ttl(key: string): Promise<number>;
}

export class OtpService {
  constructor(
    private readonly redis: RedisClientLike,
    private readonly db: Pool,
    private readonly smsProvider: SmsProvider = new LocalSmsAdapter(),
  ) {}

  /**
   * Generates and sends an OTP to a phone number.
   * Enforces rate limiting: max 5 OTPs per 10 minutes per phone.
   */
  async sendOtp(phone: string): Promise<void> {
    const rateLimitKey = `fairgo:otp:rate:${phone}`;

    // Check rate limit
    const sendCount = await this.redis.incr(rateLimitKey);
    if (sendCount === 1) {
      await this.redis.expire(rateLimitKey, OTP_RATE_LIMIT_WINDOW_SECONDS);
    }

    if (sendCount > OTP_RATE_LIMIT_MAX_SENDS) {
      log.warn('OTP rate limit exceeded', { rateLimitKey });
      throw new OtpRateLimitError(
        `Too many OTP requests. Please wait before requesting again.`,
      );
    }

    // Generate OTP
    const otp = generateNumericOtp(OTP_LENGTH);
    const otpHash = await hash(otp, 10);

    // Store in Redis with TTL (primary check path — fast)
    const redisKey = `fairgo:otp:${phone}`;
    await this.redis.setEx(
      redisKey,
      OTP_TTL_SECONDS,
      JSON.stringify({ hash: otpHash, attempts: 0 }),
    );

    // Also persist in DB (for audit, fallback)
    await this.db.query(
      `INSERT INTO auth_svc.otp_attempts (phone, otp_hash, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '${OTP_TTL_SECONDS} seconds')`,
      [phone, otpHash],
    );

    await this.smsProvider.sendOtp(phone, otp);
    log.info('OTP sent', {});
  }

  /**
   * Verifies an OTP for a phone number.
   * Enforces max attempt limit and expiry.
   */
  async verifyOtp(phone: string, otp: string): Promise<void> {
    const redisKey = `fairgo:otp:${phone}`;

    const stored = await this.redis.get(redisKey);
    if (!stored) {
      throw new OtpExpiredError('OTP has expired or was not requested');
    }

    const parsed = JSON.parse(stored) as { hash: string; attempts: number };

    if (parsed.attempts >= OTP_MAX_ATTEMPTS) {
      await this.redis.del(redisKey);
      throw new OtpInvalidError(
        'Maximum OTP attempts exceeded. Please request a new OTP.',
      );
    }

    const isValid = await compare(otp, parsed.hash);

    if (!isValid) {
      // Increment attempt count
      const updated = { ...parsed, attempts: parsed.attempts + 1 };
      const ttl = await this.redis.ttl(redisKey);
      await this.redis.setEx(redisKey, Math.max(ttl, 1), JSON.stringify(updated));
      throw new OtpInvalidError('Invalid OTP. Please check and try again.');
    }

    // OTP verified — remove from Redis
    await this.redis.del(redisKey);
    log.info('OTP verified successfully', {});
  }
}

function generateNumericOtp(length: number): string {
  const digits = '0123456789';
  let otp = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    otp += digits[randomBytes[i]! % digits.length];
  }
  return otp;
}
