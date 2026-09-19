// lib/features/booking/models/map_models.dart
// Map-agnostic domain models for location pins, routes, and vehicle markers

import 'package:flutter/material.dart';

enum VehicleType {
  sedan,
  auto,
  bike,
  premium,
}

class MapPoint {
  final double latitude;
  final double longitude;
  final String label;
  final String? address;
  final String? subtitle;

  const MapPoint({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.address,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          label == other.label;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ label.hashCode;
}

class NearbyVehicle {
  final String id;
  final double latitude;
  final double longitude;
  final double bearingDegrees;
  final VehicleType type;

  const NearbyVehicle({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.bearingDegrees = 0,
    required this.type,
  });

  IconData get icon {
    switch (type) {
      case VehicleType.sedan:
        return Icons.directions_car_rounded;
      case VehicleType.auto:
        return Icons.electric_rickshaw_rounded;
      case VehicleType.bike:
        return Icons.two_wheeler_rounded;
      case VehicleType.premium:
        return Icons.local_taxi_rounded;
    }
  }

  Color get color {
    switch (type) {
      case VehicleType.sedan:
        return const Color(0xFF0058BB);
      case VehicleType.auto:
        return const Color(0xFF059669);
      case VehicleType.bike:
        return const Color(0xFFD97706);
      case VehicleType.premium:
        return const Color(0xFF1E293B);
    }
  }
}
