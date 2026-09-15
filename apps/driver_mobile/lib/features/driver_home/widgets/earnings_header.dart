// lib/features/driver_home/widgets/earnings_header.dart

import 'package:flutter/material.dart';
import 'package:driver_app/core/theme/driver_theme.dart';
import 'package:intl/intl.dart';

class EarningsHeader extends StatelessWidget {
  final int todayEarningsPaise;
  final int tripCount;
  final int onlineMinutes;

  const EarningsHeader({
    super.key,
    required this.todayEarningsPaise,
    required this.tripCount,
    required this.onlineMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hours = onlineMinutes ~/ 60;
    final mins = onlineMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fmt.format(todayEarningsPaise / 100),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: DriverColors.primary,
            letterSpacing: -1,
          ),
        ),
        Row(
          children: [
            _Pill(label: '$tripCount trips', icon: Icons.route_rounded),
            const SizedBox(width: 8),
            _Pill(
              label: hours > 0 ? '${hours}h ${mins}m' : '${mins}m online',
              icon: Icons.timer_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DriverColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DriverColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DriverColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
