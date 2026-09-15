import type { VehicleType, DriverLocationSnapshot } from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';
import { NoDriversAvailableError } from '@fairgo/domain-errors';

const log = createLogger('matching-service:engine');

// Redis GEO key for live driver locations
const DRIVER_GEO_KEY = 'fairgo:drivers:live';
const DRIVER_LOCK_PREFIX = 'fairgo:driver:lock:';
const DRIVER_STATE_PREFIX = 'fairgo:driver:';
const LOCK_TTL_MS = 30_000; // 30 seconds — covers request/response cycle

export interface MatchRequest {
  tripId: string;
  vehicleType: VehicleType;
  pickupLat: number;
  pickupLon: number;
  radiusMeters: number;
  maxResults: number;
  requireWheelchairAccessible?: boolean;
  requireEv?: boolean;
  excludeDriverIds?: string[];
}

export interface DriverCandidate {
  driverId: string;
  distanceMeters: number;
  etaSeconds: number;
  lat: number;
  lon: number;
  vehicleType: VehicleType;
  isEV: boolean;
  isWheelchairAccessible: boolean;
  rating: number;
}

/**
 * Realtime matching engine using Redis GEO commands.
 *
 * Architecture:
 * - Driver locations are stored in Redis GEO sorted set: fairgo:drivers:live
 * - Driver state (status, vehicleType, isEV, etc.) stored in Redis Hash: fairgo:driver:<id>:state
 * - Matching uses GEORADIUS to find candidates, then filters by type/availability
 * - Assignment uses SETNX distributed lock to prevent double-assignment
 *
 * The matching loop is run by the matching service in response to booking.created events.
 * It retries with expanding radius up to 3 times before emitting driver.search-failed.
 */
export class MatchingEngine {
  constructor(
    // JUSTIFICATION: any — redis client type is complex, typed at call site
    private readonly redis: any,
  ) {}

  /**
   * Finds available driver candidates near the pickup location.
   * Applies vehicle type, accessibility, and EV filters.
   */
  async findCandidates(request: MatchRequest): Promise<DriverCandidate[]> {
    const {
      vehicleType,
      pickupLat,
      pickupLon,
      radiusMeters,
      maxResults,
      requireWheelchairAccessible = false,
      requireEv = false,
      excludeDriverIds = [],
    } = request;

    // 1. GEORADIUS query: find all drivers within radius
    // Returns: [{ member: driverId, distance: meters }]
    const geoResults: Array<{ member: string; distance: number }> = await this.redis.geoSearch(
      DRIVER_GEO_KEY,
      { longitude: pickupLon, latitude: pickupLat },
      { radius: radiusMeters, unit: 'm' },
      { SORT: 'ASC', COUNT: maxResults * 3, WITHCOORD: true, WITHDIST: true },
    );

    if (geoResults.length === 0) {
      log.info('No drivers found in geo radius', { radiusMeters, vehicleType });
      return [];
    }

    // 2. Filter by exclusions
    const filtered = geoResults.filter(
      (r) => !excludeDriverIds.includes(r.member),
    );

    // 3. Batch-fetch driver states from Redis hashes
    const candidates: DriverCandidate[] = [];
    for (const geo of filtered) {
      const driverId = geo.member;
      const stateKey = `${DRIVER_STATE_PREFIX}${driverId}:state`;
      const state = await this.redis.hGetAll(stateKey) as Record<string, string>;

      if (Object.keys(state).length === 0) continue; // stale entry — driver went offline

      // Filter checks
      if (state['status'] !== 'ONLINE') continue;
      if (state['vehicleType'] !== vehicleType) continue;
      if (requireWheelchairAccessible && state['isWheelchairAccessible'] !== 'true') continue;
      if (requireEv && state['isEV'] !== 'true') continue;

      // Check not already locked (assigned to another trip)
      const lockKey = `${DRIVER_LOCK_PREFIX}${driverId}`;
      const isLocked = await this.redis.exists(lockKey);
      if (isLocked) continue;

      // ETA estimate: 40 km/h average urban speed
      const distanceMeters = geo.distance;
      const etaSeconds = Math.ceil(distanceMeters / (40_000 / 3600)); // m / (m/s)

      candidates.push({
        driverId,
        distanceMeters,
        etaSeconds,
        lat: parseFloat(state['lat'] ?? '0'),
        lon: parseFloat(state['lon'] ?? '0'),
        vehicleType: state['vehicleType'] as VehicleType,
        isEV: state['isEV'] === 'true',
        isWheelchairAccessible: state['isWheelchairAccessible'] === 'true',
        rating: parseFloat(state['rating'] ?? '5.0'),
      });

      if (candidates.length >= maxResults) break;
    }

    // 4. Rank: closest first, then by rating
    candidates.sort((a, b) => {
      const distDiff = a.distanceMeters - b.distanceMeters;
      if (Math.abs(distDiff) > 500) return distDiff; // >500m apart: distance wins
      return b.rating - a.rating; // otherwise: rating wins
    });

    log.debug('Found candidates', { count: candidates.length, vehicleType });
    return candidates;
  }

  /**
   * Attempts to atomically lock a driver for a trip using Redis SETNX.
   * Returns true if the lock was acquired; false if driver is already locked.
   *
   * RACE CONDITION PREVENTION:
   * Uses SET ... NX PX (atomic set if not exists with TTL) to ensure
   * only one trip can lock a driver at a time, even under concurrent requests.
   */
  async tryLockDriver(driverId: string, tripId: string): Promise<boolean> {
    const lockKey = `${DRIVER_LOCK_PREFIX}${driverId}`;
    const result = await this.redis.set(lockKey, tripId, {
      NX: true,          // Only set if Not eXists
      PX: LOCK_TTL_MS,   // Auto-expire after 30 seconds
    });
    return result === 'OK';
  }

  /**
   * Releases a driver lock (when trip is cancelled or driver rejected).
   */
  async releaseDriverLock(driverId: string, tripId: string): Promise<void> {
    const lockKey = `${DRIVER_LOCK_PREFIX}${driverId}`;
    // Only delete if this trip owns the lock (Lua script for atomicity)
    const luaScript = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    `;
    await this.redis.eval(luaScript, { keys: [lockKey], arguments: [tripId] });
    log.debug('Driver lock released', { driverId, tripId });
  }

  /**
   * Updates a driver's location and state in Redis.
   * Called by the Location Service on every GPS update.
   */
  async updateDriverLocation(
    driverId: string,
    lat: number,
    lon: number,
    snapshot: Partial<DriverLocationSnapshot>,
  ): Promise<void> {
    // Atomic pipeline
    await this.redis
      .multi()
      // Update GEO position
      .geoAdd(DRIVER_GEO_KEY, { longitude: lon, latitude: lat, member: driverId })
      // Update state hash
      .hSet(`${DRIVER_STATE_PREFIX}${driverId}:state`, {
        lat: lat.toString(),
        lon: lon.toString(),
        bearing: (snapshot.bearing ?? 0).toString(),
        speed: (snapshot.speed ?? 0).toString(),
        status: snapshot.status ?? 'ONLINE',
        vehicleType: snapshot.vehicleType ?? '',
        isEV: String(snapshot.isEV ?? false),
        isWheelchairAccessible: String(snapshot.isWheelchairAccessible ?? false),
        rating: (snapshot.rating ?? 5.0).toString(),
        updatedAt: Date.now().toString(),
      })
      // TTL: driver is "online" only if seen in last 90 seconds
      .expire(`${DRIVER_STATE_PREFIX}${driverId}:state`, 90)
      .exec();
  }

  /**
   * Removes a driver from the GEO index (when they go offline).
   */
  async removeDriverFromGeo(driverId: string): Promise<void> {
    await this.redis.zRem(DRIVER_GEO_KEY, driverId);
    await this.redis.del(`${DRIVER_STATE_PREFIX}${driverId}:state`);
    log.info('Driver removed from geo index', { driverId });
  }
}
