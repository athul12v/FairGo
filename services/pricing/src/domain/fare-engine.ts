import type { Pool } from 'pg';
import type {
  VehicleType,
  FareEstimate,
  Coordinates,
  Paise,
} from '@fairgo/shared-types';
import { createLogger } from '@fairgo/logger';
import { ValidationError } from '@fairgo/domain-errors';

const log = createLogger('pricing-service:fare-engine');

interface PricingRuleRow {
  id: string;
  vehicle_type: VehicleType;
  base_fare_paise: string;
  per_km_paise: string;
  per_minute_paise: string;
  minimum_fare_paise: string;
  cancellation_fee_paise: string;
  night_charge_multiplier_bps: string;
  night_charge_start_hour: string;
  night_charge_end_hour: string;
}

interface SurgeRuleRow {
  multiplier_bps: string;
}

export interface FareEstimateInput {
  vehicleType: VehicleType;
  pickupCoordinates: Coordinates;
  dropCoordinates: Coordinates;
  distanceMeters?: number;
  durationSeconds?: number;
  zoneId?: string;
  cityId?: string;
  requestedAt?: Date;
  nearbyDriverCount?: number;
  etaSeconds?: number;
}

/**
 * Core fare calculation engine.
 *
 * FINANCIAL SAFETY: All amounts are integers in paise.
 * No floating point arithmetic is used.
 * Surge multipliers use basis points (100 bps = 1.0x, 150 bps = 1.5x).
 */
export class FareEngine {
  private static readonly GST_RATE_BPS = 500; // 5% GST on ride fare (not surge)

  constructor(private readonly db: Pool) {}

  /**
   * Estimates the fare for a given trip request.
   * Returns min/max range for display to rider.
   */
  async estimateFare(input: FareEstimateInput): Promise<FareEstimate> {
    const { vehicleType, distanceMeters = 0, durationSeconds = 0 } = input;
    const requestedAt = input.requestedAt ?? new Date();

    // 1. Fetch pricing rule (zone-specific or global)
    const rule = await this.fetchPricingRule(vehicleType, input.zoneId, input.cityId);
    if (!rule) {
      throw new ValidationError(
        `No pricing rule found for vehicle type: ${vehicleType}`,
      );
    }

    // 2. Fetch surge multiplier
    const surgeMultiplierBps = await this.fetchSurgeMultiplier(
      input.zoneId,
      vehicleType,
    );

    // 3. Calculate base fare components (all in paise, integer arithmetic)
    const baseFarePaise = parseInt(rule.base_fare_paise, 10);
    const perKmPaise = parseInt(rule.per_km_paise, 10);
    const perMinutePaise = parseInt(rule.per_minute_paise, 10);
    const minimumFarePaise = parseInt(rule.minimum_fare_paise, 10);
    const nightChargeMultiplierBps = parseInt(rule.night_charge_multiplier_bps, 10);
    const nightStartHour = parseInt(rule.night_charge_start_hour, 10);
    const nightEndHour = parseInt(rule.night_charge_end_hour, 10);

    // 4. Distance fare: perKmPaise * distanceMeters / 1000
    // Use integer arithmetic: multiply first, then divide
    const distanceFarePaise = Math.floor((perKmPaise * distanceMeters) / 1000);

    // 5. Time fare: perMinutePaise * durationSeconds / 60
    const timeFarePaise = Math.floor((perMinutePaise * durationSeconds) / 60);

    // 6. Night charge
    const isNightTime = this.isNightCharge(requestedAt, nightStartHour, nightEndHour);
    const nightChargeMultiplier = isNightTime ? nightChargeMultiplierBps : 100;

    // 7. Base + distance + time, then apply night multiplier
    const subTotalBeforeNight = baseFarePaise + distanceFarePaise + timeFarePaise;
    const subTotalAfterNight = Math.floor((subTotalBeforeNight * nightChargeMultiplier) / 100);

    // 8. Apply surge (basis points: 150 = 1.5x)
    const surgeFarePaise = Math.floor((subTotalAfterNight * surgeMultiplierBps) / 100) - subTotalAfterNight;

    // 9. GST (5% on fare, NOT on surge — see ADR)
    const taxesPaise = Math.floor((subTotalAfterNight * FareEngine.GST_RATE_BPS) / 10_000);

    // 10. Total
    const rawTotal = subTotalAfterNight + surgeFarePaise + taxesPaise;
    const estimatedFarePaise = Math.max(rawTotal, minimumFarePaise) as Paise;

    // 11. Range (±15% for display)
    const minimumDisplayPaise = Math.floor(estimatedFarePaise * 85 / 100) as Paise;
    const maximumDisplayPaise = Math.floor(estimatedFarePaise * 115 / 100) as Paise;

    log.debug('Fare calculated', {
      vehicleType,
      distanceMeters,
      durationSeconds,
      surgeMultiplierBps,
      estimatedFarePaise,
    });

    return {
      vehicleType,
      estimatedFarePaise,
      minimumFarePaise: minimumDisplayPaise,
      maximumFarePaise: maximumDisplayPaise,
      distanceMeters,
      durationSeconds,
      surgeMultiplierBps,
      breakdownPaise: {
        baseFare: baseFarePaise,
        distanceFare: distanceFarePaise,
        timeFare: timeFarePaise,
        surge: surgeFarePaise,
        taxes: taxesPaise,
      },
      etaSeconds: input.etaSeconds ?? 0,
      nearbyDriverCount: input.nearbyDriverCount ?? 0,
      currency: 'INR',
    };
  }

  /**
   * Calculates exact fare for a completed trip (used by trip service).
   * Returns a single integer amount in paise.
   */
  async calculateActualFare(
    vehicleType: VehicleType,
    distanceMeters: number,
    durationSeconds: number,
    surgeMultiplierBps: number,
    zoneId?: string,
    cityId?: string,
    tripStartedAt?: Date,
  ): Promise<Paise> {
    const rule = await this.fetchPricingRule(vehicleType, zoneId, cityId);
    if (!rule) {
      throw new ValidationError(`No pricing rule for ${vehicleType}`);
    }

    const baseFarePaise = parseInt(rule.base_fare_paise, 10);
    const perKmPaise = parseInt(rule.per_km_paise, 10);
    const perMinutePaise = parseInt(rule.per_minute_paise, 10);
    const minimumFarePaise = parseInt(rule.minimum_fare_paise, 10);
    const nightChargeMultiplierBps = parseInt(rule.night_charge_multiplier_bps, 10);

    const distanceFarePaise = Math.floor((perKmPaise * distanceMeters) / 1000);
    const timeFarePaise = Math.floor((perMinutePaise * durationSeconds) / 60);

    const isNight = tripStartedAt
      ? this.isNightCharge(
          tripStartedAt,
          parseInt(rule.night_charge_start_hour, 10),
          parseInt(rule.night_charge_end_hour, 10),
        )
      : false;
    const nightMult = isNight ? nightChargeMultiplierBps : 100;

    const subTotal = Math.floor(
      ((baseFarePaise + distanceFarePaise + timeFarePaise) * nightMult) / 100,
    );
    const withSurge = Math.floor((subTotal * surgeMultiplierBps) / 100);
    const taxes = Math.floor((subTotal * FareEngine.GST_RATE_BPS) / 10_000);
    const total = withSurge + taxes;

    return Math.max(total, minimumFarePaise) as Paise;
  }

  // ----------------------------------------------------------
  // PRIVATE HELPERS
  // ----------------------------------------------------------

  private async fetchPricingRule(
    vehicleType: VehicleType,
    zoneId?: string,
    cityId?: string,
  ): Promise<PricingRuleRow | null> {
    // Try zone-specific rule first, then city-level, then global
    const result = await this.db.query<PricingRuleRow>(
      `SELECT * FROM pricing_svc.pricing_rules
       WHERE vehicle_type = $1
         AND is_active = true
         AND (valid_until IS NULL OR valid_until > now())
         AND (
           (zone_id = $2 AND $2 IS NOT NULL)
           OR (city_id = $3 AND $3 IS NOT NULL AND zone_id IS NULL)
           OR (zone_id IS NULL AND city_id IS NULL)
         )
       ORDER BY
         CASE WHEN zone_id = $2 THEN 0
              WHEN city_id = $3 THEN 1
              ELSE 2
         END
       LIMIT 1`,
      [vehicleType, zoneId ?? null, cityId ?? null],
    );

    return result.rows[0] ?? null;
  }

  private async fetchSurgeMultiplier(
    zoneId?: string,
    vehicleType?: VehicleType,
  ): Promise<number> {
    if (!zoneId) return 100; // No zone = no surge

    const result = await this.db.query<SurgeRuleRow>(
      `SELECT multiplier_bps FROM pricing_svc.surge_rules
       WHERE zone_id = $1
         AND is_active = true
         AND (vehicle_type = $2 OR vehicle_type IS NULL)
       ORDER BY vehicle_type NULLS LAST
       LIMIT 1`,
      [zoneId, vehicleType ?? null],
    );

    return result.rows[0] ? parseInt(result.rows[0].multiplier_bps, 10) : 100;
  }

  private isNightCharge(date: Date, nightStartHour: number, nightEndHour: number): boolean {
    const hour = date.getHours();
    if (nightStartHour > nightEndHour) {
      // Spans midnight: e.g., 22–06 means hour >= 22 OR hour < 6
      return hour >= nightStartHour || hour < nightEndHour;
    }
    return hour >= nightStartHour && hour < nightEndHour;
  }
}
