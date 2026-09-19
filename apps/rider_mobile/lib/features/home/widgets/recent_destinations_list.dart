// lib/features/home/widgets/recent_destinations_list.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class RecentPlaceData {
  final String title;
  final String subtitle;
  final String distance;
  final IconData icon;

  const RecentPlaceData({
    required this.title,
    required this.subtitle,
    required this.distance,
    this.icon = Icons.history_rounded,
  });
}

class RecentDestinationsList extends StatelessWidget {
  final ValueChanged<RecentPlaceData>? onSelectDestination;

  const RecentDestinationsList({
    super.key,
    this.onSelectDestination,
  });

  static const List<RecentPlaceData> _recentItems = [
    RecentPlaceData(
      title: 'Koramangala 5th Block',
      subtitle: '80 Feet Rd, Bengaluru',
      distance: '4.2 km',
      icon: Icons.history_rounded,
    ),
    RecentPlaceData(
      title: 'Kempegowda Int\'l Airport (BLR)',
      subtitle: 'Terminal 1 & 2 Departure',
      distance: '38 km',
      icon: Icons.flight_takeoff_rounded,
    ),
    RecentPlaceData(
      title: 'MG Road Metro Station',
      subtitle: 'Mahatma Gandhi Rd, Ashok Nagar',
      distance: '5.8 km',
      icon: Icons.subway_rounded,
    ),
  ];

  void _handleTap(BuildContext context, RecentPlaceData place) {
    if (onSelectDestination != null) {
      onSelectDestination!(place);
    } else {
      try {
        context.push(AppRoutes.locationPicker);
      } catch (_) {
        // Safe fallback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Destinations',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1E2E4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _recentItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final place = entry.value;
              final isLast = idx == _recentItems.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => _handleTap(context, place),
                    borderRadius: BorderRadius.vertical(
                      top: idx == 0 ? const Radius.circular(18) : Radius.zero,
                      bottom: isLast ? const Radius.circular(18) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              place.icon,
                              size: 18,
                              color: const Color(0xFF191C1E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  place.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.distance,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 62),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F6)),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
