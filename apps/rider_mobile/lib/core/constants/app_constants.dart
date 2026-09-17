// lib/core/constants/app_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String _get(String key) {
    if (dotenv.isInitialized && dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty) {
      return dotenv.env[key]!;
    }
    throw StateError('Missing required environment variable "$key" in .env file. Please check your .env configuration.');
  }

  static String _getOptional(String key, String fallback) {
    if (dotenv.isInitialized && dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty) {
      return dotenv.env[key]!;
    }
    return fallback;
  }

  // API & Gateway (strictly loaded from .env)
  static String get baseUrl => _get('API_BASE_URL');
  static String get wsUrl => _get('WS_URL');

  // Supabase Credentials (strictly loaded from .env)
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // Storage keys (internal local cache identifiers)
  static const String keyAccessToken = 'fairgo_access_token';
  static const String keyRefreshToken = 'fairgo_refresh_token';
  static const String keyUserId = 'fairgo_user_id';
  static const String keyRiderId = 'fairgo_rider_id';
  static const String keyDeviceId = 'fairgo_device_id';
  static const String keyOnboardingDone = 'fairgo_onboarding_done';

  // Maps (loaded from .env with fallback)
  static double get defaultLat => double.tryParse(_getOptional('DEFAULT_LAT', '12.9716')) ?? 12.9716;
  static double get defaultLon => double.tryParse(_getOptional('DEFAULT_LON', '77.5946')) ?? 77.5946;
  static double get mapDefaultZoom => double.tryParse(_getOptional('MAP_DEFAULT_ZOOM', '15.0')) ?? 15.0;
  static double get mapDriverMarkerZoom => double.tryParse(_getOptional('MAP_DRIVER_MARKER_ZOOM', '14.5')) ?? 14.5;

  // Trip & Search Timeouts (loaded from .env with fallback)
  static int get driverSearchTimeoutSeconds => int.tryParse(_getOptional('DRIVER_SEARCH_TIMEOUT_SECONDS', '120')) ?? 120;
  static int get otpExpirySeconds => int.tryParse(_getOptional('OTP_EXPIRY_SECONDS', '300')) ?? 300;
  static int get driverArrivalWaitFreeSeconds => int.tryParse(_getOptional('DRIVER_ARRIVAL_WAIT_FREE_SECONDS', '180')) ?? 180;
  static int get maxWaypoints => int.tryParse(_getOptional('MAX_WAYPOINTS', '3')) ?? 3;
  static int get maxSavedPlaces => int.tryParse(_getOptional('MAX_SAVED_PLACES', '10')) ?? 10;

  // Pagination (loaded from .env with fallback)
  static int get pageSize => int.tryParse(_getOptional('PAGE_SIZE', '20')) ?? 20;

  // Network (loaded from .env with fallback)
  static int get connectTimeoutSeconds => int.tryParse(_getOptional('CONNECT_TIMEOUT_SECONDS', '10')) ?? 10;
  static int get receiveTimeoutSeconds => int.tryParse(_getOptional('RECEIVE_TIMEOUT_SECONDS', '30')) ?? 30;
  static int get maxRetries => int.tryParse(_getOptional('MAX_RETRIES', '3')) ?? 3;

  // Location (loaded from .env with fallback)
  static int get locationUpdateIntervalMs => int.tryParse(_getOptional('LOCATION_UPDATE_INTERVAL_MS', '3000')) ?? 3000;

  // Ratings
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
}
