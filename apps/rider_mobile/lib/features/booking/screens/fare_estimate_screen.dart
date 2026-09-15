// lib/features/booking/screens/fare_estimate_screen.dart
// "Choose a route" screen matching the reference design with multimodal transit badges and Terracotta "Go" buttons

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';

class _RouteBadge {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  const _RouteBadge({
    required this.icon,
    required this.label,
    required this.bgColor,
    this.textColor = Colors.white,
  });
}

class _RouteOptionItem {
  final String id;
  final List<_RouteBadge> badges;
  final String time;
  final String price;
  final String duration;
  final String subtitle;
  final String alerts;

  const _RouteOptionItem({
    required this.id,
    required this.badges,
    required this.time,
    required this.price,
    required this.duration,
    required this.subtitle,
    required this.alerts,
  });
}

class FareEstimateScreen extends StatefulWidget {
  final FareEstimateExtra? extra;

  const FareEstimateScreen({super.key, this.extra});

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
  final List<_RouteOptionItem> _routes = [
    const _RouteOptionItem(
      id: 'route_1',
      badges: [
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '1',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
        _RouteBadge(
          icon: Icons.directions_bus_rounded,
          label: '325',
          bgColor: Color(0xFFE2923A), // Amber/orange bus badge
        ),
        _RouteBadge(
          icon: Icons.train_rounded,
          label: '8',
          bgColor: Color(0xFF3CA08D), // Teal transit badge
        ),
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '8',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
      ],
      time: '3:00 pm',
      price: '\$4.98',
      duration: '24 min',
      subtitle: 'Matches preferences',
      alerts: 'No alerts',
    ),
    const _RouteOptionItem(
      id: 'route_2',
      badges: [
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '1',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
        _RouteBadge(
          icon: Icons.directions_bus_rounded,
          label: '120',
          bgColor: Color(0xFFE2923A),
        ),
        _RouteBadge(
          icon: Icons.tram_rounded,
          label: 'Local',
          bgColor: Color(0xFF3CA08D),
        ),
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '8',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
      ],
      time: '3:15 pm',
      price: '\$7.50',
      duration: '32 min',
      subtitle: 'Matches preferences',
      alerts: 'No alerts',
    ),
    const _RouteOptionItem(
      id: 'route_3',
      badges: [
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '1',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
        _RouteBadge(
          icon: Icons.directions_bus_rounded,
          label: '325',
          bgColor: Color(0xFFE2923A),
        ),
        _RouteBadge(
          icon: Icons.subway_rounded,
          label: 'T',
          bgColor: Color(0xFF3CA08D),
        ),
        _RouteBadge(
          icon: Icons.directions_walk_rounded,
          label: '8',
          bgColor: Colors.transparent,
          textColor: AppColors.onBackground,
        ),
      ],
      time: '3:15 pm',
      price: '\$4.05',
      duration: '28 min',
      subtitle: 'Matches preferences',
      alerts: 'No alerts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choose a route',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.onBackground, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert_rounded, color: AppColors.onBackground, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended route',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _routes[index];
                  return _buildRouteCard(context, item, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, _RouteOptionItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Badges and Time + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge chain
              Row(
                children: [
                  for (int i = 0; i < item.badges.length; i++) ...[
                    _buildBadge(item.badges[i]),
                    if (i < item.badges.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              // Time & Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.onBackground,
                    ),
                  ),
                  Text(
                    item.price,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration, preferences & Terracotta "Go" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.duration} min',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.alerts,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => context.push('/booking/select-service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 80), duration: 400.ms);
  }

  Widget _buildBadge(_RouteBadge badge) {
    if (badge.bgColor == Colors.transparent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 16, color: badge.textColor),
          const SizedBox(width: 2),
          Text(
            badge.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badge.textColor,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badge.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 12, color: badge.textColor),
          const SizedBox(width: 3),
          Text(
            badge.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badge.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
