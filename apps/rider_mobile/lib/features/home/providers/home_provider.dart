import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/network/api_client.dart';

class HomeState {
  final double userLat;
  final double userLon;
  final String riderName;
  final String pickupAddress;
  final String? profilePhotoUrl;
  final Set<Marker> nearbyDriverMarkers;
  final String selectedService;

  const HomeState({
    required this.userLat,
    required this.userLon,
    required this.riderName,
    this.pickupAddress = 'Indiranagar 100ft Rd, Bengaluru',
    this.profilePhotoUrl,
    this.nearbyDriverMarkers = const {},
    this.selectedService = 'daily_ride',
  });

  HomeState copyWith({
    double? userLat,
    double? userLon,
    String? riderName,
    String? pickupAddress,
    String? profilePhotoUrl,
    Set<Marker>? nearbyDriverMarkers,
    String? selectedService,
  }) => HomeState(
    userLat: userLat ?? this.userLat,
    userLon: userLon ?? this.userLon,
    riderName: riderName ?? this.riderName,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    nearbyDriverMarkers: nearbyDriverMarkers ?? this.nearbyDriverMarkers,
    selectedService: selectedService ?? this.selectedService,
  );
}

final selectedRideCategoryProvider = StateProvider<String>((ref) => 'daily_ride');

final homeProvider = FutureProvider<HomeState>((ref) async {
  // 1. Get current location safely
  Position position;
  try {
    position = await _getCurrentPosition();
  } catch (_) {
    position = Position(
      latitude: AppConstants.defaultLat,
      longitude: AppConstants.defaultLon,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  // 2. Fetch rider profile (with graceful fallback)
  String riderName = 'Rider';
  String? photoUrl;
  try {
    final dio = ref.watch(apiClientProvider);
    final profileResp = await dio.get<Map<String, dynamic>>('/v1/riders/me');
    final profileData = profileResp.data?['data'] as Map<String, dynamic>? ?? {};
    riderName = profileData['name'] as String? ?? 'Rider';
    photoUrl = profileData['profilePhotoUrl'] as String?;
  } catch (_) {
    // Graceful offline fallback
    riderName = 'Arun';
  }

  return HomeState(
    userLat: position.latitude,
    userLon: position.longitude,
    riderName: riderName,
    pickupAddress: 'Indiranagar 100ft Rd, Bengaluru',
    profilePhotoUrl: photoUrl,
    nearbyDriverMarkers: const {},
    selectedService: ref.watch(selectedRideCategoryProvider),
  );
});

Future<Position> _getCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Position(
      latitude: AppConstants.defaultLat,
      longitude: AppConstants.defaultLon,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever ||
      permission == LocationPermission.denied) {
    return Position(
      latitude: AppConstants.defaultLat,
      longitude: AppConstants.defaultLon,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
