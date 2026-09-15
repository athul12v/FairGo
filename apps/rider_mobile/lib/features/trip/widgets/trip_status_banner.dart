// lib/features/trip/widgets/trip_status_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class TripStatusBanner extends StatelessWidget {
  final String status;
  const TripStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[status] ?? _statusConfig['SEARCHING']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: config.color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 18),
          const SizedBox(width: 8),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(status)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusConfig({required this.label, required this.icon, required this.color});
}

const _statusConfig = <String, _StatusConfig>{
  'SEARCHING': _StatusConfig(label: 'Finding your driver…', icon: Icons.search_rounded, color: AppColors.info),
  'DRIVER_ASSIGNED': _StatusConfig(label: 'Driver assigned!', icon: Icons.check_circle_outline_rounded, color: AppColors.success),
  'DRIVER_EN_ROUTE': _StatusConfig(label: 'Driver on the way', icon: Icons.directions_car_rounded, color: AppColors.primary),
  'DRIVER_ARRIVED': _StatusConfig(label: 'Driver has arrived', icon: Icons.location_on_rounded, color: AppColors.warning),
  'IN_PROGRESS': _StatusConfig(label: 'Trip in progress', icon: Icons.navigation_rounded, color: AppColors.primary),
  'COMPLETED': _StatusConfig(label: 'Trip completed', icon: Icons.check_rounded, color: AppColors.success),
  'CANCELLED_BY_RIDER': _StatusConfig(label: 'Trip cancelled', icon: Icons.cancel_outlined, color: AppColors.error),
  'CANCELLED_BY_DRIVER': _StatusConfig(label: 'Driver cancelled', icon: Icons.cancel_outlined, color: AppColors.error),
};
