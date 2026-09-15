// lib/features/trip/screens/live_trip_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/features/trip/providers/live_trip_provider.dart';
import 'package:rider_app/features/trip/widgets/driver_info_card.dart';
import 'package:rider_app/features/trip/widgets/trip_status_banner.dart';
import 'package:rider_app/features/safety/widgets/sos_button.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:share_plus/share_plus.dart';

// Dark map style — same as home screen
const _mapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},{"featureType":"poi","stylers":[{"visibility":"off"}]}]''';

class LiveTripScreen extends ConsumerStatefulWidget {
  final String tripId;
  const LiveTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends ConsumerState<LiveTripScreen> {
  GoogleMapController? _mapController;
  final PanelController _panelController = PanelController();

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(liveTripProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tripAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load trip', style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: () => ref.refresh(liveTripProvider(widget.tripId)), child: const Text('Retry')),
          ]),
        ),
        data: (trip) {
          // Auto-navigate when trip completes
          if (trip.status == 'COMPLETED' || trip.status == 'CANCELLED_BY_RIDER' || trip.status == 'CANCELLED_BY_DRIVER') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (trip.status == 'COMPLETED') {
                context.go('/trip/rate/${widget.tripId}');
              } else {
                context.go(AppRoutes.home);
              }
            });
          }

          return SlidingUpPanel(
            controller: _panelController,
            minHeight: 220,
            maxHeight: 420,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: AppColors.surface,
            backdropEnabled: false,
            panel: _BottomPanel(trip: trip, tripId: widget.tripId),
            body: Stack(
              children: [
                // Full-screen live map
                GoogleMap(
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    ctrl.setMapStyle(_mapStyle);
                    // Fit camera to show driver + pickup/drop
                    if (trip.driverLat != null) {
                      ctrl.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          LatLngBounds(
                            southwest: LatLng(
                              [trip.driverLat!, trip.pickupLat, trip.dropLat].reduce((a, b) => a < b ? a : b) - 0.005,
                              [trip.driverLon!, trip.pickupLon, trip.dropLon].reduce((a, b) => a < b ? a : b) - 0.005,
                            ),
                            northeast: LatLng(
                              [trip.driverLat!, trip.pickupLat, trip.dropLat].reduce((a, b) => a > b ? a : b) + 0.005,
                              [trip.driverLon!, trip.pickupLon, trip.dropLon].reduce((a, b) => a > b ? a : b) + 0.005,
                            ),
                          ),
                          80,
                        ),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(trip.pickupLat, trip.pickupLon),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  markers: {
                    // Pickup marker
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: LatLng(trip.pickupLat, trip.pickupLon),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                      infoWindow: const InfoWindow(title: 'Pickup'),
                    ),
                    // Drop marker
                    Marker(
                      markerId: const MarkerId('drop'),
                      position: LatLng(trip.dropLat, trip.dropLon),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: const InfoWindow(title: 'Drop'),
                    ),
                    // Driver live position
                    if (trip.driverLat != null)
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: LatLng(trip.driverLat!, trip.driverLon!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: InfoWindow(title: trip.driverName),
                        rotation: trip.driverBearing,
                      ),
                  },
                  polylines: trip.routePolyline != null
                      ? {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            color: AppColors.primary,
                            width: 4,
                            points: trip.routePolyline!,
                          ),
                        }
                      : {},
                  padding: const EdgeInsets.only(bottom: 220),
                ),

                // Status banner at top
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TripStatusBanner(status: trip.status)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.3, end: 0),
                  ),
                ),

                // SOS button (always visible)
                Positioned(
                  right: 16,
                  bottom: 240,
                  child: const SosButton(),
                ),

                // Share trip button
                Positioned(
                  left: 16,
                  bottom: 240,
                  child: GestureDetector(
                    onTap: () => Share.share(
                      'Track my FairGo trip live: https://fairgo.in/track/${widget.tripId}',
                      subject: 'FairGo Trip',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.share, color: AppColors.onSurface, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final LiveTripState trip;
  final String tripId;

  const _BottomPanel({required this.trip, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Driver info card
          DriverInfoCard(trip: trip),
          const SizedBox(height: 16),

          // OTP display (visible until IN_PROGRESS)
          if (trip.status == 'DRIVER_ARRIVED') ...[
            _OtpDisplayCard(otp: trip.otpCode),
            const SizedBox(height: 12),
          ],

          // Trip progress timeline
          _TripTimeline(status: trip.status),
          const SizedBox(height: 16),

          // Fare estimate row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated fare',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
              Text(
                '₹${(trip.estimatedFarePaise / 100).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpDisplayCard extends StatelessWidget {
  final String otp;
  const _OtpDisplayCard({required this.otp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Share this OTP with your driver to start the trip',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            otp.split('').join('  '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              letterSpacing: 4,
            ),
            semanticsLabel: 'Trip OTP: $otp',
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white24);
  }
}

class _TripTimeline extends StatelessWidget {
  final String status;
  const _TripTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TripStep('Driver assigned', 'DRIVER_ASSIGNED'),
      _TripStep('Driver en route', 'DRIVER_EN_ROUTE'),
      _TripStep('Driver arrived', 'DRIVER_ARRIVED'),
      _TripStep('Trip started', 'IN_PROGRESS'),
    ];

    final currentIndex = steps.indexWhere((s) => s.status == status);

    return Row(
      children: steps.asMap().map((i, step) {
        final isDone = i < currentIndex;
        final isCurrent = i == currentIndex;
        return MapEntry(
          i,
          Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isCurrent ? AppColors.primary : AppColors.surfaceBorder,
                        border: isCurrent
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        boxShadow: isCurrent
                            ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'Inter',
                        color: isCurrent ? AppColors.primary : AppColors.onSurfaceDisabled,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 1.5,
                      color: i < currentIndex ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).values.toList(),
    );
  }
}

class _TripStep {
  final String label;
  final String status;
  const _TripStep(this.label, this.status);
}
