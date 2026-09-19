// lib/features/home/widgets/popular_destinations_list.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class DestinationSuggestion {
  final String title;
  final String subtitle;
  final String fare;
  final String tag;
  final IconData icon;
  final Color tagColor;

  const DestinationSuggestion({
    required this.title,
    required this.subtitle,
    required this.fare,
    required this.tag,
    required this.icon,
    this.tagColor = const Color(0xFF059669), // Green
  });
}

class PopularDestinationsList extends StatelessWidget {
  final ValueChanged<DestinationSuggestion>? onSelectDestination;
  final VoidCallback? onViewMap;

  const PopularDestinationsList({
    super.key,
    this.onSelectDestination,
    this.onViewMap,
  });

  static const List<DestinationSuggestion> _suggestions = [
    DestinationSuggestion(
      title: 'Grand Central Terminal',
      subtitle: '89 E 42nd St • 12 min away',
      fare: '\$16.20',
      tag: 'Fastest',
      icon: Icons.subway_rounded,
      tagColor: Color(0xFF059669),
    ),
    DestinationSuggestion(
      title: 'Downtown Financial Hub',
      subtitle: 'Battery Park Plaza • 18 min away',
      fare: '\$22.50',
      tag: 'Direct',
      icon: Icons.business_rounded,
      tagColor: Color(0xFF0058BB),
    ),
    DestinationSuggestion(
      title: 'Marina Bay Skyway',
      subtitle: 'Pier 14 Terminal • 9 min away',
      fare: '\$14.80',
      tag: 'Popular',
      icon: Icons.directions_boat_rounded,
      tagColor: Color(0xFFD97706),
    ),
    DestinationSuggestion(
      title: 'Kempegowda Int\'l Airport (BLR)',
      subtitle: 'Terminal 1 & 2 • 35 min away',
      fare: '\$34.00',
      tag: 'Express',
      icon: Icons.flight_takeoff_rounded,
      tagColor: Color(0xFF7C3AED),
    ),
  ];

  void _handleTap(BuildContext context, DestinationSuggestion item) {
    if (onSelectDestination != null) {
      onSelectDestination!(item);
    } else {
      try {
        context.push(AppRoutes.locationPicker);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Suggestions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: Color(0xFF191C1E),
              ),
            ),
            InkWell(
              onTap: () {
                if (onViewMap != null) {
                  onViewMap!();
                } else {
                  try {
                    context.push(AppRoutes.locationPicker);
                  } catch (_) {}
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View map',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0058BB),
                  ),
                ),
              ),
            ),
          ],
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
            children: _suggestions.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == _suggestions.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => _handleTap(context, item),
                    borderRadius: BorderRadius.vertical(
                      top: idx == 0 ? const Radius.circular(18) : Radius.zero,
                      bottom: isLast ? const Radius.circular(18) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 19,
                              color: const Color(0xFF191C1E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.fare,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.tag,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: item.tagColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 64),
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
