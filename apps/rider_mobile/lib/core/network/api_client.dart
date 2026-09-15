// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/services/device_id_service.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(dio),
    _RequestIdInterceptor(),
    _LogInterceptor(),
  ]);

  return dio;
});

/// Injects Bearer token and handles 401 token refresh with retry.
class _AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();
  static bool _isRefreshing = false;
  static final List<Function> _queue = [];

  final Dio _dio;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        _queue.add(() async {
          handler.resolve(await _retry(err.requestOptions));
        });
        return;
      }

      _isRefreshing = true;
      try {
        final newTokens = await _refreshTokens();
        if (newTokens != null) {
          await _storage.write(key: AppConstants.keyAccessToken, value: newTokens['accessToken']);
          await _storage.write(key: AppConstants.keyRefreshToken, value: newTokens['refreshToken']);

          // Retry all queued requests
          for (final fn in _queue) {
            fn();
          }
          _queue.clear();

          handler.resolve(await _retry(err.requestOptions));
        } else {
          // Refresh failed — clear tokens and force logout
          await _storage.deleteAll();
          handler.next(err);
        }
      } catch (_) {
        await _storage.deleteAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }
    handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch<dynamic>(requestOptions);
  }

  Future<Map<String, String>?> _refreshTokens() async {
    final refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    final deviceId = await DeviceIdService.getDeviceId();
    if (refreshToken == null || deviceId == null) return null;

    try {
      final resp = await Dio().post<Map<String, dynamic>>(
        '${AppConstants.baseUrl}/v1/auth/token/refresh',
        data: {'refreshToken': refreshToken, 'deviceId': deviceId},
      );
      final data = resp.data?['data'] as Map<String, dynamic>?;
      return data != null
          ? {
              'accessToken': data['accessToken'] as String,
              'refreshToken': data['refreshToken'] as String,
            }
          : null;
    } catch (_) {
      return null;
    }
  }
}

/// Injects X-Request-ID and X-Correlation-ID on every request.
class _RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    const uuid = Uuid();
    options.headers['X-Request-ID'] = uuid.v4();
    options.headers['X-Correlation-ID'] = uuid.v4();
    handler.next(options);
  }
}

/// Dev-only request/response logger.
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

/// Standard API response envelope
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  final List<dynamic>? details;

  const ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String,
        message: json['message'] as String,
        details: json['details'] as List<dynamic>?,
      );
}
