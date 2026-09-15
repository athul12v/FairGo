// lib/core/constants/driver_constants.dart

class DriverConstants {
  DriverConstants._();

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

  static const String keyAccessToken = 'fairgo_driver_access_token';
  static const String keyRefreshToken = 'fairgo_driver_refresh_token';
  static const String keyDriverId = 'fairgo_driver_id';
  static const String keyDeviceId = 'fairgo_driver_device_id';
  static const String keyOnboardingDone = 'fairgo_driver_onboarding_done';

  // Trip request
  static const int tripRequestExpirySeconds = 30;
  static const int reconnectDelaySeconds = 3;

  // Location
  static const int stationaryIntervalSeconds = 30;
  static const int slowIntervalSeconds = 10;
  static const int fastIntervalSeconds = 3;
  static const double slowSpeedKmh = 2.0;
  static const double fastSpeedKmh = 20.0;
  static const int locationDistanceFilterMeters = 5;
}
