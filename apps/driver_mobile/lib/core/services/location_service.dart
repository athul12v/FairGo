// lib/core/services/location_service.dart (Driver App)
// Battery-aware adaptive GPS location streaming per ADR-003

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:driver_app/core/constants/driver_constants.dart';

/// Battery-aware location update intervals (matches AGENTS.md spec):
/// - Stationary (speed < 2 km/h): 30 seconds
/// - Slow (2–20 km/h): 10 seconds
/// - Fast (> 20 km/h): 3 seconds
const _stationaryInterval = Duration(seconds: 30);
const _slowInterval = Duration(seconds: 10);
const _fastInterval = Duration(seconds: 3);

class LocationStreamService extends Notifier<AsyncValue<Position?>> {
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  DateTime? _lastSentAt;

  @override
  AsyncValue<Position?> build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _channel?.sink.close();
    });
    return const AsyncData(null);
  }

  /// Starts sending GPS location to the FairGo location service via WebSocket.
  Future<void> startStreaming(String driverId, String accessToken) async {
    await _ensurePermission();

    // Connect WebSocket
    final uri = Uri.parse(
      '${DriverConstants.wsUrl}/driver/location?driverId=$driverId&token=$accessToken',
    );
    _channel = WebSocketChannel.connect(uri);

    // High-accuracy stream (geolocator handles OS-level duty cycling)
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Only emit if moved >= 5 meters
      ),
    ).listen((position) {
      _lastPosition = position;
      state = AsyncData(position);

      // Adaptive send rate based on speed
      final interval = _intervalForSpeed(position.speed);
      final now = DateTime.now();
      final lastSent = _lastSentAt;

      if (lastSent == null || now.difference(lastSent) >= interval) {
        _sendLocation(position);
        _lastSentAt = now;
      }
    });
  }

  void _sendLocation(Position position) {
    if (_channel == null) return;
    final payload = jsonEncode({
      'type': 'location.update',
      'payload': {
        'lat': position.latitude,
        'lon': position.longitude,
        'bearing': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
    try {
      _channel!.sink.add(payload);
    } catch (e) {
      debugPrint('[LocationService] Send error: $e');
    }
  }

  void stopStreaming() {
    _positionSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = const AsyncData(null);
  }

  static Duration _intervalForSpeed(double speedMps) {
    final kmh = speedMps * 3.6;
    if (kmh < 2) return _stationaryInterval;
    if (kmh < 20) return _slowInterval;
    return _fastInterval;
  }

  static Future<void> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
  }
}

final locationStreamServiceProvider = NotifierProvider<LocationStreamService, AsyncValue<Position?>>(
  LocationStreamService.new,
);
