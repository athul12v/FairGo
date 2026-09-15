// lib/features/driver_home/providers/trip_request_provider.dart
// WebSocket-driven trip request state — incoming trip appears, driver has 30s to accept/decline

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:driver_app/core/constants/driver_constants.dart';
import 'package:driver_app/core/network/api_client.dart';

part 'trip_request_provider.g.dart';

class TripRequest {
  final String tripId;
  final String serviceType;
  final String vehicleType;
  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLon;
  final double dropLat;
  final double dropLon;
  final double distanceKm;
  final int estimatedFarePaise;
  final int etaToPickupSeconds;
  final int expiresIn; // seconds
  final double riderRating;
  final int riderTripCount;
  final bool isSurge;
  final int surgeMultiplierBps;

  const TripRequest({
    required this.tripId,
    required this.serviceType,
    required this.vehicleType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropLat,
    required this.dropLon,
    required this.distanceKm,
    required this.estimatedFarePaise,
    required this.etaToPickupSeconds,
    required this.expiresIn,
    required this.riderRating,
    required this.riderTripCount,
    required this.isSurge,
    required this.surgeMultiplierBps,
  });

  factory TripRequest.fromJson(Map<String, dynamic> json) => TripRequest(
    tripId: json['tripId'] as String,
    serviceType: json['serviceType'] as String? ?? 'CAB',
    vehicleType: json['vehicleType'] as String? ?? 'CAB_MINI',
    pickupAddress: json['pickupAddress'] as String? ?? '',
    dropAddress: json['dropAddress'] as String? ?? '',
    pickupLat: (json['pickupLat'] as num).toDouble(),
    pickupLon: (json['pickupLon'] as num).toDouble(),
    dropLat: (json['dropLat'] as num).toDouble(),
    dropLon: (json['dropLon'] as num).toDouble(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    estimatedFarePaise: json['estimatedFarePaise'] as int? ?? 0,
    etaToPickupSeconds: json['etaToPickupSeconds'] as int? ?? 0,
    expiresIn: json['expiresIn'] as int? ?? 30,
    riderRating: (json['riderRating'] as num?)?.toDouble() ?? 5.0,
    riderTripCount: json['riderTripCount'] as int? ?? 0,
    isSurge: json['isSurge'] as bool? ?? false,
    surgeMultiplierBps: json['surgeMultiplierBps'] as int? ?? 100,
  );
}

@riverpod
class TripRequestNotifier extends _$TripRequestNotifier {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _expiryTimer;
  final _player = AudioPlayer();

  @override
  TripRequest? build() {
    ref.onDispose(() {
      _sub?.cancel();
      _channel?.sink.close();
      _expiryTimer?.cancel();
      _player.dispose();
    });
    _connectMatchingSocket();
    return null;
  }

  void _connectMatchingSocket() {
    final uri = Uri.parse('${DriverConstants.wsUrl}/driver/requests');
    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
      (message) {
        try {
          final event = jsonDecode(message as String) as Map<String, dynamic>;
          if (event['type'] == 'trip.request') {
            final request = TripRequest.fromJson(
              event['payload'] as Map<String, dynamic>,
            );
            state = request;

            // Play chime
            _player.play(AssetSource('sounds/trip_request.mp3')).ignore();

            // Auto-expire after `expiresIn` seconds
            _expiryTimer?.cancel();
            _expiryTimer = Timer(Duration(seconds: request.expiresIn), () {
              if (state?.tripId == request.tripId) {
                state = null;
              }
            });
          }
        } catch (e) {
          debugPrint('[TripRequest WS] Error: $e');
        }
      },
      onError: (_) {
        // Reconnect after 3s
        Future.delayed(const Duration(seconds: 3), _connectMatchingSocket);
      },
    );
  }

  Future<void> accept() async {
    final request = state;
    if (request == null) return;
    _expiryTimer?.cancel();

    final dio = ref.read(apiClientProvider);
    await dio.post<void>('/v1/trips/${request.tripId}/driver/accept');
    state = null;
  }

  void decline() {
    final request = state;
    if (request == null) return;
    _expiryTimer?.cancel();
    state = null;

    // Notify backend (best-effort)
    final dio = ref.read(apiClientProvider);
    dio.post<void>('/v1/trips/${request.tripId}/driver/decline').ignore();
  }
}

// Convenience alias
final tripRequestProvider = tripRequestNotifierProvider;
