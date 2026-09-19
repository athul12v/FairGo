// lib/features/driver_home/providers/driver_status_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver_app/core/network/api_client.dart';

class DriverStatus {
  final bool isOnline;
  final double currentLat;
  final double currentLon;
  final String status; // 'OFFLINE' | 'ONLINE_IDLE' | 'EN_ROUTE' | 'ON_TRIP'
  final int todayEarningsPaise;
  final int todayTripCount;
  final int onlineMinutesToday;

  const DriverStatus({
    required this.isOnline,
    required this.currentLat,
    required this.currentLon,
    required this.status,
    this.todayEarningsPaise = 0,
    this.todayTripCount = 0,
    this.onlineMinutesToday = 0,
  });

  Set<Marker> get heatmapMarkers => const {};

  DriverStatus copyWith({
    bool? isOnline,
    double? currentLat,
    double? currentLon,
    String? status,
    int? todayEarningsPaise,
    int? todayTripCount,
    int? onlineMinutesToday,
  }) {
    return DriverStatus(
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      status: status ?? this.status,
      todayEarningsPaise: todayEarningsPaise ?? this.todayEarningsPaise,
      todayTripCount: todayTripCount ?? this.todayTripCount,
      onlineMinutesToday: onlineMinutesToday ?? this.onlineMinutesToday,
    );
  }
}

class DriverStatusNotifier extends AsyncNotifier<DriverStatus> {
  StreamSubscription<Position>? _positionSub;

  @override
  Future<DriverStatus> build() async {
    ref.onDispose(() {
      _positionSub?.cancel();
    });

    double lat = 12.9716;
    double lon = 77.5946;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 3));
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (_) {}

    return DriverStatus(
      isOnline: false,
      currentLat: lat,
      currentLon: lon,
      status: 'OFFLINE',
    );
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    final current = state.valueOrNull ??
        const DriverStatus(
          isOnline: false,
          currentLat: 12.9716,
          currentLon: 77.5946,
          status: 'OFFLINE',
        );

    state = AsyncData(current.copyWith(
      isOnline: isOnline,
      status: isOnline ? 'ONLINE_IDLE' : 'OFFLINE',
    ));

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>(
        '/v1/drivers/status',
        data: {
          'isOnline': isOnline,
          'lat': current.currentLat,
          'lon': current.currentLon,
        },
      );
    } catch (_) {}

    if (isOnline) {
      _startLocationTracking();
    } else {
      _positionSub?.cancel();
    }
  }

  void _startLocationTracking() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          currentLat: pos.latitude,
          currentLon: pos.longitude,
        ));
      }
    });
  }
}

final driverStatusProvider =
    AsyncNotifierProvider<DriverStatusNotifier, DriverStatus>(
  DriverStatusNotifier.new,
);
