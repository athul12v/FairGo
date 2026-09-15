import { OtpService } from '../../domain/otp.service.js';
import { OtpRateLimitError, OtpInvalidError, OtpExpiredError } from '@fairgo/domain-errors';

// Mock dependencies
const mockRedisGet = jest.fn();
const mockRedisSet = jest.fn();
const mockRedisIncr = jest.fn();
const mockRedisExpire = jest.fn();
const mockRedisDel = jest.fn();
const mockRedisTtl = jest.fn();
const mockRedisSetEx = jest.fn();

const mockRedis = {
  get: mockRedisGet,
  set: mockRedisSet,
  incr: mockRedisIncr,
  expire: mockRedisExpire,
  del: mockRedisDel,
  ttl: mockRedisTtl,
  setEx: mockRedisSetEx,
};

const mockDbQuery = jest.fn().mockResolvedValue({ rows: [] });
const mockDb = { query: mockDbQuery } as any;

const mockSmsProvider = { sendOtp: jest.fn().mockResolvedValue(undefined) };

describe('OtpService', () => {
  let service: OtpService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new OtpService(mockRedis as any, mockDb, mockSmsProvider);
  });

  describe('sendOtp', () => {
    it('sends OTP on first request', async () => {
      mockRedisIncr.mockResolvedValueOnce(1);
      mockRedisExpire.mockResolvedValueOnce(1);
      mockRedisSetEx.mockResolvedValueOnce('OK');

      await service.sendOtp('+919876543210');

      expect(mockSmsProvider.sendOtp).toHaveBeenCalledTimes(1);
      expect(mockDbQuery).toHaveBeenCalledTimes(1);
    });

    it('throws OtpRateLimitError when rate limit exceeded', async () => {
      mockRedisIncr.mockResolvedValueOnce(6); // already at 6 (limit is 5)

      await expect(service.sendOtp('+919876543210')).rejects.toThrow(OtpRateLimitError);
      expect(mockSmsProvider.sendOtp).not.toHaveBeenCalled();
    });
  });

  describe('verifyOtp', () => {
    it('throws OtpExpiredError when Redis key not found', async () => {
      mockRedisGet.mockResolvedValueOnce(null);

      await expect(service.verifyOtp('+919876543210', '123456')).rejects.toThrow(OtpExpiredError);
    });

    it('throws OtpInvalidError when max attempts exceeded', async () => {
      mockRedisGet.mockResolvedValueOnce(
        JSON.stringify({ hash: 'some-hash', attempts: 3 }),
      );
      mockRedisDel.mockResolvedValueOnce(1);

      await expect(service.verifyOtp('+919876543210', '123456')).rejects.toThrow(OtpInvalidError);
    });
  });
});
