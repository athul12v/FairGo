// lib/features/driver_home/screens/driver_home_screen.dart
// The driver's main screen: online/offline toggle, trip request bottom sheet, earnings summary

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:driver_app/core/theme/driver_theme.dart';
import 'package:driver_app/features/driver_home/providers/driver_status_provider.dart';
import 'package:driver_app/features/driver_home/providers/trip_request_provider.dart';
import 'package:driver_app/features/driver_home/widgets/earnings_header.dart';
import 'package:driver_app/features/driver_home/widgets/trip_request_sheet.dart';
import 'package:driver_app/features/driver_home/widgets/online_toggle.dart';
import 'package:driver_app/core/router/driver_routes.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const _mapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#0f1a18"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#1a2e2a"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e4a3a"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a1210"}]},{"featureType":"poi","stylers":[{"visibility":"off"}]}]''';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  GoogleMapController? _mapController;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(driverStatusProvider);
    final tripRequest = ref.watch(tripRequestProvider);

    // Keep screen on while online
    final isOnline = statusAsync.valueOrNull?.isOnline ?? false;
    WakelockPlus.toggle(enable: isOnline);

    return Scaffold(
      backgroundColor: DriverColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // Map
          statusAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: DriverColors.primary)),
            error: (_, __) => Container(color: DriverColors.background),
            data: (status) => GoogleMap(
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                ctrl.setMapStyle(_mapStyle);
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(status.currentLat, status.currentLon),
                zoom: 14.5,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              markers: status.heatmapMarkers,
              padding: const EdgeInsets.only(bottom: 200),
            ),
          ),

          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0, height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DriverColors.background.withOpacity(0.95), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header: earnings + status
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: statusAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (s) => EarningsHeader(
                            todayEarningsPaise: s.todayEarningsPaise,
                            tripCount: s.todayTripCount,
                            onlineMinutes: s.onlineMinutesToday,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Notification bell
                      GestureDetector(
                        onTap: () => context.push(DriverRoutes.notifications),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DriverColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: DriverColors.surfaceBorder),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: DriverColors.onBackground, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Online/Offline toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: statusAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (s) => OnlineToggle(
                      isOnline: s.isOnline,
                      onToggle: (v) async {
                        HapticFeedback.mediumImpact();
                        await ref.read(driverStatusProvider.notifier).setOnlineStatus(v);
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ],
            ),
          ),

          // Offline overlay
          if (!(statusAsync.valueOrNull?.isOnline ?? false))
            Positioned.fill(
              child: Container(
                color: DriverColors.background.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/offline_car.json',
                        width: 180,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.wifi_off,
                          color: DriverColors.onSurfaceMuted,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You\'re offline',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toggle online to start receiving trips',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: DriverColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

          // Trip request bottom sheet
          if (tripRequest != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TripRequestSheet(
                request: tripRequest,
                onAccept: () async {
                  HapticFeedback.heavyImpact();
                  await ref.read(tripRequestProvider.notifier).accept();
                  if (mounted) context.go(DriverRoutes.liveTrip);
                },
                onDecline: () {
                  HapticFeedback.mediumImpact();
                  ref.read(tripRequestProvider.notifier).decline();
                },
              ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut),
            ),
        ],
      ),
      bottomNavigationBar: tripRequest == null
          ? _DriverBottomNav(currentIndex: _navIndex, onTap: (i) {
              setState(() => _navIndex = i);
              switch (i) {
                case 1: context.push(DriverRoutes.earnings); break;
                case 2: context.push(DriverRoutes.documents); break;
                case 3: context.push(DriverRoutes.profile); break;
              }
            })
          : null,
    );
  }
}

class _DriverBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DriverBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.map_rounded, 'Map'),
      (Icons.account_balance_wallet_rounded, 'Earnings'),
      (Icons.badge_rounded, 'Documents'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: DriverColors.surface,
        border: Border(top: BorderSide(color: DriverColors.surfaceBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final isSelected = e.key == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(e.key),
                  child: Semantics(
                    label: e.value.$2,
                    selected: isSelected,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          e.value.$1,
                          color: isSelected ? DriverColors.primary : DriverColors.onSurfaceMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.value.$2,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? DriverColors.primary : DriverColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
