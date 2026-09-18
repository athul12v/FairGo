import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class HomeState {
  final double userLat;
  final double userLon;
  final String riderName;
  final String? profilePhotoUrl;
  final Set<Marker> nearbyDriverMarkers;
  final String selectedService;

  const HomeState({
    required this.userLat,
    required this.userLon,
    required this.riderName,
    this.profilePhotoUrl,
    this.nearbyDriverMarkers = const {},
    this.selectedService = 'CAB',
  });

  HomeState copyWith({
    double? userLat,
    double? userLon,
    String? riderName,
    String? profilePhotoUrl,
    Set<Marker>? nearbyDriverMarkers,
    String? selectedService,
  }) => HomeState(
    userLat: userLat ?? this.userLat,
    userLon: userLon ?? this.userLon,
    riderName: riderName ?? this.riderName,
    profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    nearbyDriverMarkers: nearbyDriverMarkers ?? this.nearbyDriverMarkers,
    selectedService: selectedService ?? this.selectedService,
  );
}

final homeProvider = FutureProvider<HomeState>((ref) async {
  // 1. Get current location
  final position = await _getCurrentPosition();

  // 2. Fetch rider profile
  final dio = ref.watch(apiClientProvider);
  final profileResp = await dio.get<Map<String, dynamic>>('/v1/riders/me');
  final profileData = profileResp.data?['data'] as Map<String, dynamic>? ?? {};

  // 3. Fetch nearby drivers (for map markers)
  final nearbyResp = await dio.get<Map<String, dynamic>>(
    '/v1/location/nearby-drivers',
    queryParameters: {
      'lat': position.latitude,
      'lon': position.longitude,
      'vehicleType': 'CAB_MINI',
      'radius': 3000,
    },
  );
  final drivers = (nearbyResp.data?['data']?['drivers'] as List<dynamic>?) ?? [];
  final markers = drivers.asMap().map((i, d) {
    final driverMap = d as Map<String, dynamic>;
    final driverId = driverMap['driverId'] as String? ?? 'driver_$i';
    return MapEntry(
      driverId,
      Marker(
        markerId: MarkerId(driverId),
        position: LatLng(
          (driverMap['lat'] as num).toDouble(),
          (driverMap['lon'] as num).toDouble(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: driverMap['name'] as String? ?? 'Driver'),
      ),
    );
  }).values.toSet();

  return HomeState(
    userLat: position.latitude,
    userLon: position.longitude,
    riderName: profileData['name'] as String? ?? 'Rider',
    profilePhotoUrl: profileData['profilePhotoUrl'] as String?,
    nearbyDriverMarkers: markers,
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
