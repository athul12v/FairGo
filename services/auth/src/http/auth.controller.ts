import type { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import type { AuthService } from '../domain/auth.service.js';
import { isDomainError } from '@fairgo/domain-errors';

// ----------------------------------------------------------
// Request validation schemas
// ----------------------------------------------------------

const requestOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\+[1-9]\d{7,14}$/, 'Phone must be in E.164 format e.g. +919876543210'),
});

const verifyOtpSchema = z.object({
  phone: z.string().regex(/^\+[1-9]\d{7,14}$/),
  otp: z.string().length(6, 'OTP must be 6 digits'),
  deviceId: z.string().min(1, 'Device ID is required').max(255),
  deviceType: z.enum(['ANDROID', 'IOS', 'WEB']),
  fcmToken: z.string().optional(),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
  deviceId: z.string().min(1),
});

// ----------------------------------------------------------
// Controller (thin — delegates to AuthService)
// ----------------------------------------------------------

export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /v1/auth/otp/request
   * Request an OTP for phone verification.
   */
  requestOtp = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = requestOtpSchema.parse(req.body);
      await this.authService.requestPhoneOtp(body.phone);
      res.status(200).json({ success: true, data: { message: 'OTP sent successfully' } });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /v1/auth/otp/verify
   * Verify OTP and receive JWT tokens.
   */
  verifyOtp = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = verifyOtpSchema.parse(req.body);
      const result = await this.authService.verifyPhoneOtp(
        body.phone,
        body.otp,
        body.deviceId,
        body.deviceType,
        body.fcmToken,
      );

      res.status(200).json({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          isNewUser: result.isNewUser,
        },
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /v1/auth/token/refresh
   * Exchange a refresh token for a new token pair.
   */
  refresh = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = refreshSchema.parse(req.body);
      const tokens = await this.authService.refreshTokens(body.refreshToken, body.deviceId);
      res.status(200).json({ success: true, data: tokens });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /v1/auth/logout
   * Revoke current session.
   */
  logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.sub;
      const sessionId = req.user?.sessionId;
      if (!userId || !sessionId) {
        res.status(401).json({ success: false, error: { code: 'ERR_AUTH_INVALID_TOKEN', message: 'Unauthorized' } });
        return;
      }
      await this.authService.logout(userId, sessionId);
      res.status(200).json({ success: true, data: { message: 'Logged out successfully' } });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /v1/auth/logout/all
   * Revoke all sessions for the current user.
   */
  logoutAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.sub;
      if (!userId) {
        res.status(401).json({ success: false, error: { code: 'ERR_AUTH_INVALID_TOKEN', message: 'Unauthorized' } });
        return;
      }
      await this.authService.logoutAllDevices(userId);
      res.status(200).json({ success: true, data: { message: 'All sessions revoked' } });
    } catch (err) {
      next(err);
    }
  };
}

// Extend Express Request type to include decoded user
declare global {
  namespace Express {
    interface Request {
      user?: {
        sub: string;
        sessionId: string;
        role: string;
        riderId?: string;
        driverId?: string;
      };
      requestId?: string;
      correlationId?: string;
    }
  }
}
