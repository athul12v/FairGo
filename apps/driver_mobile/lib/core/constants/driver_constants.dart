// lib/core/constants/driver_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class DriverConstants {
  DriverConstants._();

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

  // API & Gateway (loaded from .env)
  static String get baseUrl => _get('API_BASE_URL');
  static String get wsUrl => _get('WS_URL');

  // Firebase Configuration (loaded from .env with fallback)
  static String get firebaseProjectId => _getOptional('FIREBASE_PROJECT_ID', 'fairgo-app');
  static String get firebaseApiKey => _getOptional('FIREBASE_API_KEY', '');
  static String get firebaseAppId => _getOptional('FIREBASE_APP_ID', '');

  // Storage keys (internal local secure storage identifiers)
  static const String keyAccessToken = 'fairgo_driver_access_token';
  static const String keyRefreshToken = 'fairgo_driver_refresh_token';
  static const String keyDriverId = 'fairgo_driver_id';
  static const String keyDeviceId = 'fairgo_driver_device_id';
  static const String keyOnboardingDone = 'fairgo_driver_onboarding_done';

  // Trip request
  static int get tripRequestExpirySeconds => int.tryParse(_getOptional('TRIP_REQUEST_EXPIRY_SECONDS', '30')) ?? 30;
  static int get reconnectDelaySeconds => int.tryParse(_getOptional('RECONNECT_DELAY_SECONDS', '3')) ?? 3;

  // Location & Battery Awareness
  static int get stationaryIntervalSeconds => int.tryParse(_getOptional('STATIONARY_INTERVAL_SECONDS', '30')) ?? 30;
  static int get slowIntervalSeconds => int.tryParse(_getOptional('SLOW_INTERVAL_SECONDS', '10')) ?? 10;
  static int get fastIntervalSeconds => int.tryParse(_getOptional('FAST_INTERVAL_SECONDS', '3')) ?? 3;
  static double get slowSpeedKmh => double.tryParse(_getOptional('SLOW_SPEED_KMH', '2.0')) ?? 2.0;
  static double get fastSpeedKmh => double.tryParse(_getOptional('FAST_SPEED_KMH', '20.0')) ?? 20.0;
  static int get locationDistanceFilterMeters => int.tryParse(_getOptional('LOCATION_DISTANCE_FILTER_METERS', '5')) ?? 5;
}
