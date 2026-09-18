// lib/features/trip/providers/live_trip_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rider_app/core/constants/app_constants.dart';
import 'package:rider_app/core/network/api_client.dart';

class LiveTripState {
  final String tripId;
  final String status;
  final String driverName;
  final String driverPhone;
  final String? driverPhotoUrl;
  final double driverRating;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String otpCode;
  final double pickupLat;
  final double pickupLon;
  final String pickupAddress;
  final double dropLat;
  final double dropLon;
  final String dropAddress;
  final double? driverLat;
  final double? driverLon;
  final double driverBearing;
  final int etaSeconds;
  final int estimatedFarePaise;
  final List<LatLng>? routePolyline;
  final bool isChatEnabled;
  final int unreadMessages;

  const LiveTripState({
    required this.tripId,
    required this.status,
    required this.driverName,
    required this.driverPhone,
    this.driverPhotoUrl,
    required this.driverRating,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.otpCode,
    required this.pickupLat,
    required this.pickupLon,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLon,
    required this.dropAddress,
    this.driverLat,
    this.driverLon,
    this.driverBearing = 0,
    required this.etaSeconds,
    required this.estimatedFarePaise,
    this.routePolyline,
    this.isChatEnabled = true,
    this.unreadMessages = 0,
  });

  LiveTripState copyWith({
    String? status,
    double? driverLat,
    double? driverLon,
    double? driverBearing,
    int? etaSeconds,
    List<LatLng>? routePolyline,
    int? unreadMessages,
  }) => LiveTripState(
    tripId: tripId,
    status: status ?? this.status,
    driverName: driverName,
    driverPhone: driverPhone,
    driverPhotoUrl: driverPhotoUrl,
    driverRating: driverRating,
    vehicleType: vehicleType,
    vehicleNumber: vehicleNumber,
    vehicleModel: vehicleModel,
    otpCode: otpCode,
    pickupLat: pickupLat,
    pickupLon: pickupLon,
    pickupAddress: pickupAddress,
    dropLat: dropLat,
    dropLon: dropLon,
    dropAddress: dropAddress,
    driverLat: driverLat ?? this.driverLat,
    driverLon: driverLon ?? this.driverLon,
    driverBearing: driverBearing ?? this.driverBearing,
    etaSeconds: etaSeconds ?? this.etaSeconds,
    estimatedFarePaise: estimatedFarePaise,
    routePolyline: routePolyline ?? this.routePolyline,
    isChatEnabled: isChatEnabled,
    unreadMessages: unreadMessages ?? this.unreadMessages,
  );
}

class LiveTripNotifier extends AutoDisposeFamilyAsyncNotifier<LiveTripState, String> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  late String _tripId;

  @override
  Future<LiveTripState> build(String arg) async {
    _tripId = arg;
    // Fetch initial trip state from REST
    final dio = ref.watch(apiClientProvider);
    final resp = await dio.get<Map<String, dynamic>>('/v1/trips/$_tripId');
    final data = resp.data?['data'] as Map<String, dynamic>? ?? {};

    final initialState = _tripFromJson(data);

    // Connect WebSocket for live updates
    _connectWebSocket(_tripId, initialState);

    // Cleanup on dispose
    ref.onDispose(() {
      _subscription?.cancel();
      _channel?.sink.close();
    });

    return initialState;
  }

  void _connectWebSocket(String tripId, LiveTripState initial) {
    final wsUri = Uri.parse('${AppConstants.wsUrl}/trips/$tripId');
    _channel = WebSocketChannel.connect(wsUri);

    _subscription = _channel!.stream.listen(
      (message) {
        try {
          final event = jsonDecode(message as String) as Map<String, dynamic>;
          final type = event['type'] as String?;
          final payload = event['payload'] as Map<String, dynamic>? ?? {};

          final current = state.valueOrNull;
          if (current == null) return;

          switch (type) {
            case 'driver.location.updated':
              state = AsyncData(current.copyWith(
                driverLat: (payload['lat'] as num).toDouble(),
                driverLon: (payload['lon'] as num).toDouble(),
                driverBearing: (payload['bearing'] as num?)?.toDouble() ?? 0,
                etaSeconds: payload['etaSeconds'] as int? ?? current.etaSeconds,
              ));
              break;

            case 'trip.status.updated':
              state = AsyncData(current.copyWith(
                status: payload['status'] as String? ?? current.status,
              ));
              break;

            case 'chat.message.received':
              state = AsyncData(current.copyWith(
                unreadMessages: current.unreadMessages + 1,
              ));
              break;
          }
        } catch (e) {
          debugPrint('[LiveTrip WS] Parse error: $e');
        }
      },
      onError: (error) {
        debugPrint('[LiveTrip WS] Error: $error');
        // Auto-reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (state.hasValue) {
            _connectWebSocket(tripId, state.requireValue);
          }
        });
      },
      onDone: () {
        debugPrint('[LiveTrip WS] Connection closed');
      },
    );
  }

  Future<void> cancelTrip(String reason) async {
    final dio = ref.read(apiClientProvider);
    await dio.post<void>('/v1/trips/$_tripId/cancel', data: {'reason': reason});
  }

  static LiveTripState _tripFromJson(Map<String, dynamic> data) {
    final driver = data['driver'] as Map<String, dynamic>? ?? {};
    final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
    final stops = data['stops'] as List<dynamic>? ?? [];
    final pickup = stops.isNotEmpty ? stops.first as Map<String, dynamic> : <String, dynamic>{};
    final drop = stops.length > 1 ? stops.last as Map<String, dynamic> : <String, dynamic>{};

    return LiveTripState(
      tripId: data['id'] as String? ?? '',
      status: data['status'] as String? ?? 'SEARCHING',
      driverName: driver['name'] as String? ?? 'Driver',
      driverPhone: driver['phone'] as String? ?? '',
      driverPhotoUrl: driver['profilePhotoUrl'] as String?,
      driverRating: (driver['rating'] as num?)?.toDouble() ?? 5.0,
      vehicleType: vehicle['type'] as String? ?? 'CAB_MINI',
      vehicleNumber: vehicle['licensePlate'] as String? ?? '',
      vehicleModel: '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
      otpCode: data['otpCode'] as String? ?? '------',
      pickupLat: (pickup['lat'] as num?)?.toDouble() ?? 0,
      pickupLon: (pickup['lon'] as num?)?.toDouble() ?? 0,
      pickupAddress: pickup['address'] as String? ?? '',
      dropLat: (drop['lat'] as num?)?.toDouble() ?? 0,
      dropLon: (drop['lon'] as num?)?.toDouble() ?? 0,
      dropAddress: drop['address'] as String? ?? '',
      driverLat: (driver['currentLat'] as num?)?.toDouble(),
      driverLon: (driver['currentLon'] as num?)?.toDouble(),
      etaSeconds: data['etaSeconds'] as int? ?? 0,
      estimatedFarePaise: data['estimatedFarePaise'] as int? ?? 0,
    );
  }
}

final liveTripProvider = AsyncNotifierProvider.autoDispose.family<LiveTripNotifier, LiveTripState, String>(
  LiveTripNotifier.new,
);
