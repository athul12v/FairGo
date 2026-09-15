// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // API & Supabase
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://10.0.2.2:3007',
  );
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-id.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Storage keys
  static const String keyAccessToken = 'fairgo_access_token';
  static const String keyRefreshToken = 'fairgo_refresh_token';
  static const String keyUserId = 'fairgo_user_id';
  static const String keyRiderId = 'fairgo_rider_id';
  static const String keyDeviceId = 'fairgo_device_id';
  static const String keyOnboardingDone = 'fairgo_onboarding_done';

  // Maps
  static const double defaultLat = 12.9716; // Bengaluru
  static const double defaultLon = 77.5946;
  static const double mapDefaultZoom = 15.0;
  static const double mapDriverMarkerZoom = 14.5;

  // Trip
  static const int driverSearchTimeoutSeconds = 120;
  static const int otpExpirySeconds = 300;
  static const int driverArrivalWaitFreeSeconds = 180; // 3 min free wait
  static const int maxWaypoints = 3;
  static const int maxSavedPlaces = 10;

  // Pagination
  static const int pageSize = 20;

  // Network
  static const int connectTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // Location
  static const int locationUpdateIntervalMs = 3000;

  // Ratings
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
}
