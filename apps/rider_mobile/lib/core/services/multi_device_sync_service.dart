// lib/core/services/multi_device_sync_service.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/services/device_id_service.dart';

/// Represents a synchronization event payload broadcast from server
class SyncEvent {
  final String eventId;
  final String eventType;
  final int sequenceNumber;
  final String originDeviceId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SyncEvent({
    required this.eventId,
    required this.eventType,
    required this.sequenceNumber,
    required this.originDeviceId,
    required this.timestamp,
    required this.data,
  });

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt() ?? 0,
      originDeviceId: (json['originDeviceId'] as String?) ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Provider for multi-device synchronization state
final multiDeviceSyncServiceProvider =
    StateNotifierProvider<MultiDeviceSyncNotifier, MultiDeviceSyncState>((ref) {
  return MultiDeviceSyncNotifier(ref);
});

class MultiDeviceSyncState {
  final bool isConnected;
  final int lastAcknowledgedSequence;
  final String? currentDeviceId;
  final Map<String, dynamic> syncedState;

  const MultiDeviceSyncState({
    required this.isConnected,
    required this.lastAcknowledgedSequence,
    this.currentDeviceId,
    this.syncedState = const {},
  });

  MultiDeviceSyncState copyWith({
    bool? isConnected,
    int? lastAcknowledgedSequence,
    String? currentDeviceId,
    Map<String, dynamic>? syncedState,
  }) {
    return MultiDeviceSyncState(
      isConnected: isConnected ?? this.isConnected,
      lastAcknowledgedSequence:
          lastAcknowledgedSequence ?? this.lastAcknowledgedSequence,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      syncedState: syncedState ?? this.syncedState,
    );
  }
}

class MultiDeviceSyncNotifier extends StateNotifier<MultiDeviceSyncState> {
  // ignore: unused_field
  final Ref _ref;
  StreamSubscription? _socketSubscription;

  MultiDeviceSyncNotifier(this._ref)
      : super(const MultiDeviceSyncState(
          isConnected: false,
          lastAcknowledgedSequence: 0,
        )) {
    _init();
  }

  Future<void> _init() async {
    final deviceId = await DeviceIdService.getDeviceId();
    state = state.copyWith(currentDeviceId: deviceId);
  }

  /// Process incoming sync events across multiple devices
  void handleIncomingSyncEvent(Map<String, dynamic> rawJson) {
    try {
      final event = SyncEvent.fromJson(rawJson);

      // Monotonic sequence verification: Ignore stale or duplicate out-of-order events
      if (event.sequenceNumber <= state.lastAcknowledgedSequence &&
          state.lastAcknowledgedSequence != 0) {
        return;
      }

      // If event originated from this exact device, we already have optimistic state;
      // however, we update the acknowledged sequence.
      final isSelf = event.originDeviceId == state.currentDeviceId &&
          state.currentDeviceId != null &&
          state.currentDeviceId!.isNotEmpty;

      final updatedStateMap = Map<String, dynamic>.from(state.syncedState);
      updatedStateMap[event.eventType] = event.data;

      state = state.copyWith(
        lastAcknowledgedSequence: event.sequenceNumber,
        syncedState: updatedStateMap,
      );

      // Dispatch specific domain actions based on event type
      _dispatchDomainReconciliation(event, isSelf);
    } catch (_) {
      // Gracefully handle malformed sync frames
    }
  }

  void _dispatchDomainReconciliation(SyncEvent event, bool isSelf) {
    switch (event.eventType) {
      case 'trip.status.changed':
      case 'trip.driver_assigned':
      case 'trip.cancelled':
      case 'trip.completed':
        // Re-fetch or synchronize active trip state
        break;
      case 'wallet.balance.updated':
        // Re-fetch wallet state
        break;
      case 'auth.session.revoked':
        // Handle remote logout from another device
        break;
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}
