import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import type { AuthController } from './auth.controller.js';
import { authMiddleware } from './middleware/auth.middleware.js';

export function createAuthRouter(controller: AuthController): Router {
  const router = Router();

  // OTP request — strict rate limit: 5 per hour per IP
  const otpRequestLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: { code: 'ERR_RATE_LIMIT', message: 'Too many OTP requests. Try again in an hour.' } },
    keyGenerator: (req) => req.ip ?? 'unknown',
  });

  // General auth endpoints — 30 per minute per IP
  const generalLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: { code: 'ERR_RATE_LIMIT', message: 'Too many requests.' } },
  });

  // Public routes
  router.post('/otp/request', otpRequestLimiter, controller.requestOtp);
  router.post('/otp/verify', generalLimiter, controller.verifyOtp);
  router.post('/token/refresh', generalLimiter, controller.refresh);

  // Authenticated routes
  router.post('/logout', authMiddleware, controller.logout);
  router.post('/logout/all', authMiddleware, controller.logoutAll);

  return router;
}
