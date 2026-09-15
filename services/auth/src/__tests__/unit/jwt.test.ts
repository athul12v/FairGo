import { issueTokens, verifyAccessToken, verifyRefreshToken } from '../../infrastructure/jwt.js';
import { InvalidTokenError, ExpiredTokenError } from '@fairgo/domain-errors';
import { UserRole } from '@fairgo/shared-types';

// Set test secret
process.env['JWT_SECRET'] = 'test-secret-at-least-32-chars-long-for-tests';
process.env['JWT_EXPIRES_IN'] = '1h';
process.env['JWT_REFRESH_EXPIRES_IN'] = '7d';

describe('JWT infrastructure', () => {
  const payload = {
    sub: '550e8400-e29b-41d4-a716-446655440000',
    role: UserRole.RIDER,
    riderId: '550e8400-e29b-41d4-a716-446655440001',
    deviceId: 'test-device-123',
    sessionId: '550e8400-e29b-41d4-a716-446655440002',
  };

  describe('issueTokens', () => {
    it('issues a valid token pair', async () => {
      const tokens = await issueTokens(payload);

      expect(tokens.accessToken).toBeTruthy();
      expect(tokens.refreshToken).toBeTruthy();
      expect(tokens.expiresAt).toBeInstanceOf(Date);
      expect(tokens.expiresAt.getTime()).toBeGreaterThan(Date.now());
    });
  });

  describe('verifyAccessToken', () => {
    it('successfully verifies a valid access token', async () => {
      const { accessToken } = await issueTokens(payload);
      const claims = await verifyAccessToken(accessToken);

      expect(claims.sub).toBe(payload.sub);
      expect(claims.role).toBe(UserRole.RIDER);
      expect(claims.riderId).toBe(payload.riderId);
      expect(claims.sessionId).toBe(payload.sessionId);
    });

    it('throws InvalidTokenError for a garbage token', async () => {
      await expect(verifyAccessToken('not.a.jwt')).rejects.toThrow(InvalidTokenError);
    });

    it('throws InvalidTokenError when using refresh token as access token', async () => {
      const { refreshToken } = await issueTokens(payload);
      // Refresh token has wrong audience — should fail
      await expect(verifyAccessToken(refreshToken)).rejects.toThrow(InvalidTokenError);
    });
  });

  describe('verifyRefreshToken', () => {
    it('successfully verifies a valid refresh token', async () => {
      const { refreshToken } = await issueTokens(payload);
      const { sub, sessionId } = await verifyRefreshToken(refreshToken);

      expect(sub).toBe(payload.sub);
      expect(sessionId).toBe(payload.sessionId);
    });

    it('throws InvalidTokenError for garbage token', async () => {
      await expect(verifyRefreshToken('garbage')).rejects.toThrow(InvalidTokenError);
    });
  });
});
