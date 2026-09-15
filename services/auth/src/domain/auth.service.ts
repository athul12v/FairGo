import { randomUUID } from 'crypto';
import type { Pool, PoolClient } from 'pg';
import { createLogger } from '@fairgo/logger';
import type { UserRole } from '@fairgo/shared-types';
import { RiderNotFoundError, ValidationError } from '@fairgo/domain-errors';
import { issueTokens, verifyRefreshToken } from '../infrastructure/jwt.js';
import { OtpService } from './otp.service.js';

const log = createLogger('auth-service:auth');

export interface UserRow {
  id: string;
  phone: string | null;
  email: string | null;
  phone_verified: boolean;
  email_verified: boolean;
  role: UserRole;
  is_active: boolean;
  suspended_at: Date | null;
}

export interface SessionRow {
  id: string;
  user_id: string;
  device_id: string;
  expires_at: Date;
  is_active: boolean;
}

export class AuthService {
  constructor(
    private readonly db: Pool,
    private readonly otpService: OtpService,
  ) {}

  // ----------------------------------------------------------
  // PHONE OTP FLOW
  // ----------------------------------------------------------

  async requestPhoneOtp(phone: string): Promise<void> {
    await this.otpService.sendOtp(phone);
  }

  async verifyPhoneOtp(
    phone: string,
    otp: string,
    deviceId: string,
    deviceType: 'ANDROID' | 'IOS' | 'WEB',
    fcmToken?: string,
  ): Promise<{ accessToken: string; refreshToken: string; isNewUser: boolean }> {
    // 1. Verify OTP
    await this.otpService.verifyOtp(phone, otp);

    // 2. Find or create user
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      let user = await this.findUserByPhone(client, phone);
      const isNewUser = !user;

      if (!user) {
        const result = await client.query<UserRow>(
          `INSERT INTO auth_svc.users (phone, phone_verified, role)
           VALUES ($1, true, 'RIDER')
           RETURNING *`,
          [phone],
        );
        user = result.rows[0]!;
        log.info('New user created via phone OTP', { role: 'RIDER' });
      } else {
        if (!user.is_active) {
          throw new ValidationError('Account is suspended. Please contact support.');
        }
        // Mark phone as verified if not already
        if (!user.phone_verified) {
          await client.query(
            'UPDATE auth_svc.users SET phone_verified = true, updated_at = now() WHERE id = $1',
            [user.id],
          );
        }
        // Update last login
        await client.query(
          'UPDATE auth_svc.users SET last_login_at = now(), updated_at = now() WHERE id = $1',
          [user.id],
        );
      }

      // 3. Create session
      const sessionId = randomUUID();
      const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

      await client.query(
        `INSERT INTO auth_svc.sessions (id, user_id, device_id, device_type, fcm_token, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT DO NOTHING`,
        [sessionId, user.id, deviceId, deviceType, fcmToken ?? null, expiresAt],
      );

      await client.query('COMMIT');

      // 4. Issue tokens
      const tokens = await issueTokens({
        sub: user.id,
        role: user.role,
        deviceId,
        sessionId,
      });

      return {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isNewUser,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // ----------------------------------------------------------
  // TOKEN REFRESH
  // ----------------------------------------------------------

  async refreshTokens(
    refreshToken: string,
    deviceId: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const { sub: userId, sessionId } = await verifyRefreshToken(refreshToken);

    // Verify session is still active in DB
    const sessionResult = await this.db.query<SessionRow>(
      `SELECT * FROM auth_svc.sessions
       WHERE id = $1 AND user_id = $2 AND device_id = $3
         AND is_active = true AND expires_at > now()`,
      [sessionId, userId, deviceId],
    );

    if (sessionResult.rows.length === 0) {
      throw new ValidationError('Session expired or invalid. Please log in again.');
    }

    // Fetch user for latest role
    const userResult = await this.db.query<UserRow>(
      'SELECT * FROM auth_svc.users WHERE id = $1 AND is_active = true',
      [userId],
    );

    if (userResult.rows.length === 0) {
      throw new RiderNotFoundError('User not found or suspended');
    }

    const user = userResult.rows[0]!;
    const tokens = await issueTokens({
      sub: user.id,
      role: user.role,
      deviceId,
      sessionId,
    });

    return { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken };
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------

  async logout(userId: string, sessionId: string): Promise<void> {
    await this.db.query(
      `UPDATE auth_svc.sessions
       SET is_active = false, revoked_at = now()
       WHERE id = $1 AND user_id = $2`,
      [sessionId, userId],
    );
    log.info('Session revoked', { sessionId });
  }

  async logoutAllDevices(userId: string): Promise<void> {
    await this.db.query(
      `UPDATE auth_svc.sessions
       SET is_active = false, revoked_at = now()
       WHERE user_id = $1 AND is_active = true`,
      [userId],
    );
    log.info('All sessions revoked for user');
  }

  // ----------------------------------------------------------
  // ADMIN OPERATIONS
  // ----------------------------------------------------------

  async suspendUser(userId: string, reason: string, actorId: string): Promise<void> {
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE auth_svc.users
         SET is_active = false, suspended_at = now(), suspension_reason = $1, updated_at = now()
         WHERE id = $2`,
        [reason, userId],
      );

      // Revoke all sessions
      await client.query(
        `UPDATE auth_svc.sessions
         SET is_active = false, revoked_at = now()
         WHERE user_id = $1`,
        [userId],
      );

      // Audit log
      await client.query(
        `INSERT INTO auth_svc.audit_logs (actor_id, action, resource_type, resource_id, changes)
         VALUES ($1, 'user.suspended', 'USER', $2, $3::jsonb)`,
        [actorId, userId, JSON.stringify({ reason })],
      );

      await client.query('COMMIT');
      log.info('User suspended', { actorId });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async reinstateUser(userId: string, actorId: string): Promise<void> {
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE auth_svc.users
         SET is_active = true, suspended_at = null, suspension_reason = null, updated_at = now()
         WHERE id = $1`,
        [userId],
      );

      await client.query(
        `INSERT INTO auth_svc.audit_logs (actor_id, action, resource_type, resource_id)
         VALUES ($1, 'user.reinstated', 'USER', $2)`,
        [actorId, userId],
      );

      await client.query('COMMIT');
      log.info('User reinstated', { actorId });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------

  private async findUserByPhone(
    client: PoolClient,
    phone: string,
  ): Promise<UserRow | null> {
    const result = await client.query<UserRow>(
      'SELECT * FROM auth_svc.users WHERE phone = $1 AND deleted_at IS NULL',
      [phone],
    );
    return result.rows[0] ?? null;
  }
}
