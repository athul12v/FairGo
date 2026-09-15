// lib/features/driver_home/widgets/trip_request_sheet.dart
// The most critical UI component: incoming trip request with countdown timer

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:driver_app/core/theme/driver_theme.dart';
import 'package:driver_app/features/driver_home/providers/trip_request_provider.dart';

class TripRequestSheet extends StatefulWidget {
  final TripRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TripRequestSheet({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<TripRequestSheet> createState() => _TripRequestSheetState();
}

class _TripRequestSheetState extends State<TripRequestSheet>
    with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.request.expiresIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining--;
          if (_remaining <= 0) {
            _timer?.cancel();
            widget.onDecline();
          }
        });
      }
    });

    // Pulse animation for accept button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fare = widget.request.estimatedFarePaise / 100;
    final etaMin = (widget.request.etaToPickupSeconds / 60).ceil();
    final distanceKm = widget.request.distanceKm.toStringAsFixed(1);
    final isSurge = widget.request.isSurge;
    final surgeX = (widget.request.surgeMultiplierBps / 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: DriverColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isSurge ? DriverColors.accent : DriverColors.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSurge ? DriverColors.accent : DriverColors.primary).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: DriverColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header row: type + timer
              Row(
                children: [
                  // Service type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DriverColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DriverColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.request.vehicleType.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DriverColors.primary,
                      ),
                    ),
                  ),
                  if (isSurge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: DriverColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DriverColors.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: DriverColors.accent, size: 14),
                          Text(
                            '${surgeX}x Surge',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DriverColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Countdown timer
                  _CountdownTimer(seconds: _remaining),
                ],
              ),
              const SizedBox(height: 20),

              // Fare — large and prominent
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${fare.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: isSurge ? DriverColors.accent : DriverColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoPill(icon: Icons.straighten, label: '${distanceKm} km'),
                      const SizedBox(height: 4),
                      _InfoPill(icon: Icons.timer_outlined, label: '$etaMin min away'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _RouteRow(
                      icon: Icons.radio_button_checked,
                      color: DriverColors.primary,
                      label: widget.request.pickupAddress,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          color: DriverColors.surfaceBorder,
                          thickness: 1.5,
                        ),
                      ),
                    ),
                    _RouteRow(
                      icon: Icons.location_on,
                      color: DriverColors.error,
                      label: widget.request.dropAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Rider info row
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: DriverColors.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.request.riderRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DriverColors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.request.riderTripCount} trips',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: DriverColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Accept / Decline buttons
              Row(
                children: [
                  // Decline
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DriverColors.onSurfaceMuted,
                        side: const BorderSide(color: DriverColors.surfaceBorder),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Decline', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Accept — pulsing green button
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, child) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [DriverColors.primary, DriverColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: DriverColors.primary.withOpacity(
                                0.3 + 0.3 * _pulseController.value,
                              ),
                              blurRadius: 16 + 12 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  final int seconds;
  const _CountdownTimer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final color = seconds <= 10 ? DriverColors.error : DriverColors.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$seconds',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    ).animate(target: seconds <= 10 ? 1 : 0).shake(duration: 500.ms, hz: 4);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DriverColors.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: DriverColors.onSurfaceMuted)),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _RouteRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: DriverColors.onBackground),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
