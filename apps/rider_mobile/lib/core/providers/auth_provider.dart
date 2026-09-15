import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/services/device_id_service.dart';
import 'package:dio/dio.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isOnboarded;
  final String? userId;
  final String? riderId;

  const AuthState({
    required this.isAuthenticated,
    required this.isOnboarded,
    this.userId,
    this.riderId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isOnboarded,
    String? userId,
    String? riderId,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    isOnboarded: isOnboarded ?? this.isOnboarded,
    userId: userId ?? this.userId,
    riderId: riderId ?? this.riderId,
  );
}

class AuthStateNotifier extends AsyncNotifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<AuthState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
    final userId = await _storage.read(key: AppConstants.keyUserId);
    final riderId = await _storage.read(key: AppConstants.keyRiderId);

    return AuthState(
      isAuthenticated: accessToken != null,
      isOnboarded: isOnboarded,
      userId: userId,
      riderId: riderId,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    state = AsyncData(state.requireValue.copyWith(isOnboarded: true));
  }

  Future<({bool isNewUser})> verifyOtp({
    required String phone,
    required String otp,
    required String deviceType,
    String? fcmToken,
  }) async {
    final dio = ref.read(apiClientProvider);
    final deviceId = await DeviceIdService.getDeviceId() ?? '';

    final resp = await dio.post<Map<String, dynamic>>(
      '/v1/auth/otp/verify',
      data: {
        'phone': phone,
        'otp': otp,
        'deviceId': deviceId,
        'deviceType': deviceType,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
    );

    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? {};
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final isNewUser = data['isNewUser'] as bool? ?? true;

    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);

    // Decode userId from JWT (simple base64 decode of payload)
    final userId = _extractSubFromJwt(accessToken);
    if (userId != null) {
      await _storage.write(key: AppConstants.keyUserId, value: userId);
    }

    state = AsyncData(state.requireValue.copyWith(
      isAuthenticated: true,
      userId: userId,
    ));

    return (isNewUser: isNewUser);
  }

  Future<void> logout() async {
    final dio = ref.read(apiClientProvider);
    try {
      await dio.post<void>('/v1/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
    state = AsyncData(state.requireValue.copyWith(
      isAuthenticated: false,
      userId: null,
      riderId: null,
    ));
  }

  String? _extractSubFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return json['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final authStateNotifierProvider =
    AsyncNotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

// Re-export alias for convenience
final authStateProvider = authStateNotifierProvider;
