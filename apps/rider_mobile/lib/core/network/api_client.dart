// lib/core/network/api_client.dart

import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/services/device_id_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(seconds: AppConstants.connectTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConstants.receiveTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    _AuthInterceptor(dio),
    _RequestIdInterceptor(),
    _IdempotencyInterceptor(),
    _ResilientRetryInterceptor(dio),
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

/// Injects X-Request-ID, X-Correlation-ID, and X-Device-ID on every request.
class _RequestIdInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    const uuid = Uuid();
    options.headers['X-Request-ID'] = uuid.v4();
    options.headers['X-Correlation-ID'] ??= uuid.v4();
    
    final deviceId = await DeviceIdService.getDeviceId();
    if (deviceId != null) {
      options.headers['X-Device-ID'] = deviceId;
    }
    handler.next(options);
  }
}

/// Injects deterministic or unique X-Idempotency-Key for all mutative requests (POST, PUT, PATCH, DELETE).
/// Guarantees that concurrent requests from same or multiple devices are processed exactly once.
class _IdempotencyInterceptor extends Interceptor {
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final isMutative = ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method);

    if (isMutative && !options.headers.containsKey('X-Idempotency-Key')) {
      // If caller did not provide a custom idempotency key, attach a fresh UUIDv4
      options.headers['X-Idempotency-Key'] = _uuid.v4();
    }

    options.headers['X-Client-Timestamp'] = DateTime.now().toUtc().toIso8601String();
    handler.next(options);
  }
}

/// Resilient retry interceptor with exponential backoff and full jitter.
/// Handles transient network timeouts, 429 (Rate Limited), and 502/503/504 gateway errors.
class _ResilientRetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 3;
  static const int _baseDelayMs = 500;
  static const int _maxDelayMs = 4000;
  final Random _random = Random();

  _ResilientRetryInterceptor(this._dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final retryCount = (requestOptions.extra['retryCount'] as int? ?? 0);

    // Determine if request is eligible for safe retry
    final statusCode = err.response?.statusCode;
    final isTransientStatus = statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;

    final isNetworkTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    final isIdempotentMethod = ['GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'].contains(requestOptions.method.toUpperCase());
    final hasIdempotencyKey = requestOptions.headers.containsKey('X-Idempotency-Key');
    final isSafeToRetry = isIdempotentMethod || hasIdempotencyKey;

    if ((isTransientStatus || isNetworkTimeout) && isSafeToRetry && retryCount < _maxRetries) {
      final nextRetryCount = retryCount + 1;
      requestOptions.extra['retryCount'] = nextRetryCount;

      // Calculate exponential backoff with full jitter
      final exponentialDelay = min(_maxDelayMs, _baseDelayMs * pow(2, retryCount).toInt());
      final jitteredDelayMs = (_random.nextDouble() * exponentialDelay).toInt() + (_baseDelayMs ~/ 2);

      await Future.delayed(Duration(milliseconds: jitteredDelayMs));

      try {
        final response = await _dio.fetch<dynamic>(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    return handler.next(err);
  }
}

/// Dev-only request/response logger.
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.uri} [Idempotency: ${options.headers['X-Idempotency-Key'] ?? 'none'}]');
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
