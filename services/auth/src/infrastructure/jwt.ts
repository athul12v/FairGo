import * as jose from 'jose';
import type { JwtClaims, UserRole } from '@fairgo/shared-types';
import { InvalidTokenError, ExpiredTokenError } from '@fairgo/domain-errors';

const JWT_SECRET = process.env['JWT_SECRET'];
const JWT_EXPIRES_IN = process.env['JWT_EXPIRES_IN'] ?? '24h';
const JWT_REFRESH_EXPIRES_IN = process.env['JWT_REFRESH_EXPIRES_IN'] ?? '30d';

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}

const secretKey = new TextEncoder().encode(JWT_SECRET);

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
}

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
  riderId?: string;
  driverId?: string;
  corporateAccountId?: string;
  deviceId: string;
  sessionId: string;
}

/**
 * Issues a JWT access token with FairGo custom claims.
 */
export async function issueTokens(payload: AccessTokenPayload): Promise<TokenPair> {
  const now = new Date();
  const expiresAt = new Date(now.getTime() + parseDuration(JWT_EXPIRES_IN));

  const accessToken = await new jose.SignJWT({
    sub: payload.sub,
    role: payload.role,
    ...(payload.riderId && { riderId: payload.riderId }),
    ...(payload.driverId && { driverId: payload.driverId }),
    ...(payload.corporateAccountId && { corporateAccountId: payload.corporateAccountId }),
    deviceId: payload.deviceId,
    sessionId: payload.sessionId,
  })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(JWT_EXPIRES_IN)
    .setIssuer('fairgo-auth')
    .setAudience('fairgo-api')
    .sign(secretKey);

  const refreshToken = await new jose.SignJWT({
    sub: payload.sub,
    sessionId: payload.sessionId,
    type: 'refresh',
  })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(JWT_REFRESH_EXPIRES_IN)
    .setIssuer('fairgo-auth')
    .sign(secretKey);

  return { accessToken, refreshToken, expiresAt };
}

/**
 * Verifies and decodes a JWT access token.
 * Throws InvalidTokenError or ExpiredTokenError on failure.
 */
export async function verifyAccessToken(token: string): Promise<JwtClaims> {
  try {
    const { payload } = await jose.jwtVerify(token, secretKey, {
      issuer: 'fairgo-auth',
      audience: 'fairgo-api',
    });

    return payload as unknown as JwtClaims;
  } catch (err) {
    if (err instanceof jose.errors.JWTExpired) {
      throw new ExpiredTokenError('Access token has expired');
    }
    throw new InvalidTokenError('Invalid access token');
  }
}

/**
 * Verifies a refresh token and returns the sessionId and userId.
 */
export async function verifyRefreshToken(
  token: string,
): Promise<{ sub: string; sessionId: string }> {
  try {
    const { payload } = await jose.jwtVerify(token, secretKey, {
      issuer: 'fairgo-auth',
    });

    if (payload['type'] !== 'refresh') {
      throw new InvalidTokenError('Not a refresh token');
    }

    return {
      sub: payload.sub as string,
      sessionId: payload['sessionId'] as string,
    };
  } catch (err) {
    if (err instanceof jose.errors.JWTExpired) {
      throw new ExpiredTokenError('Refresh token has expired');
    }
    if (err instanceof InvalidTokenError) throw err;
    throw new InvalidTokenError('Invalid refresh token');
  }
}

function parseDuration(duration: string): number {
  const match = /^(\d+)([smhd])$/.exec(duration);
  if (!match) throw new Error(`Invalid duration: ${duration}`);
  const value = parseInt(match[1]!, 10);
  const unit = match[2]!;
  const multipliers: Record<string, number> = { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 };
  return value * (multipliers[unit] ?? 1000);
}
