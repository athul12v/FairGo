import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../../infrastructure/jwt.js';
import { InvalidTokenError, ExpiredTokenError, InsufficientPermissionsError } from '@fairgo/domain-errors';
import type { UserRole } from '@fairgo/shared-types';

/**
 * Middleware: verifies Bearer JWT and attaches decoded claims to req.user.
 * Throws 401 for missing/invalid tokens, 401 for expired tokens.
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const authHeader = req.headers['authorization'];

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      error: { code: 'ERR_AUTH_INVALID_TOKEN', message: 'Authorization header missing or malformed' },
    });
    return;
  }

  const token = authHeader.slice(7);

  try {
    const claims = await verifyAccessToken(token);
    req.user = {
      sub: claims.sub,
      sessionId: claims.sessionId,
      role: claims.role,
      ...(claims.riderId !== undefined && { riderId: claims.riderId }),
      ...(claims.driverId !== undefined && { driverId: claims.driverId }),
    };
    next();
  } catch (err) {
    if (err instanceof ExpiredTokenError) {
      res.status(401).json({
        success: false,
        error: { code: 'ERR_AUTH_TOKEN_EXPIRED', message: 'Access token has expired' },
      });
    } else {
      res.status(401).json({
        success: false,
        error: { code: 'ERR_AUTH_INVALID_TOKEN', message: 'Invalid access token' },
      });
    }
  }
}

/**
 * Middleware factory: enforces that req.user has one of the required roles.
 */
export function requireRoles(...roles: UserRole[]): (req: Request, res: Response, next: NextFunction) => void {
  return (req: Request, res: Response, next: NextFunction): void => {
    const userRole = req.user?.role as UserRole | undefined;
    if (!userRole || !roles.includes(userRole)) {
      res.status(403).json({
        success: false,
        error: {
          code: 'ERR_AUTH_INSUFFICIENT_PERMISSIONS',
          message: `Required role: ${roles.join(' or ')}`,
        },
      });
      return;
    }
    next();
  };
}
