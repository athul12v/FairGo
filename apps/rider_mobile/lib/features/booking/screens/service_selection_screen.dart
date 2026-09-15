// lib/features/booking/screens/service_selection_screen.dart
// "Choose a ride" screen matching the reference design with 3D isometric map background, mint selected ride card, and terracotta CTA

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/core/widgets/fairgo_illustrations.dart';

class _RideTier {
  final String id;
  final String name;
  final int capacity;
  final String eta;
  final String badge;
  final String price;
  final IconData icon;

  const _RideTier({
    required this.id,
    required this.name,
    required this.capacity,
    required this.eta,
    required this.badge,
    required this.price,
    required this.icon,
  });
}

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  int _selectedIndex = 0;

  final List<_RideTier> _tiers = const [
    _RideTier(
      id: 'go',
      name: 'FairGo Go',
      capacity: 4,
      eta: '12:34 pm • 2 min away',
      badge: 'Cheaper',
      price: '\$23.03',
      icon: Icons.directions_car_rounded,
    ),
    _RideTier(
      id: 'comfort',
      name: 'Black SUV',
      capacity: 4,
      eta: '12:34 pm • 2 min away',
      badge: 'Comfort',
      price: '\$28.50',
      icon: Icons.directions_car_filled_rounded,
    ),
    _RideTier(
      id: 'black',
      name: 'Black Sedan',
      capacity: 4,
      eta: '12:34 pm • 2 min away',
      badge: 'Executive',
      price: '\$34.00',
      icon: Icons.local_taxi_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTier = _tiers[_selectedIndex];

    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // 1. Isometric 3D Map in the background
          const Positioned.fill(
            bottom: 340,
            child: IsometricCityScene(
              height: double.infinity,
              showPins: true,
            ),
          ),

          // Floating Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onBackground),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),

          // 2. Bottom Sheet ("Choose a ride")
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle pill
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    const Center(
                      child: Text(
                        'Choose a ride',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Tiers List
                    for (int i = 0; i < _tiers.length; i++) ...[
                      _buildTierTile(_tiers[i], i),
                      if (i < _tiers.length - 1) const SizedBox(height: 10),
                    ],

                    const SizedBox(height: 20),

                    // Action Footer: Terracotta CTA + Payment method box
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push(AppRoutes.searchingDriver),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Choose ${selectedTier.name}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => context.push(AppRoutes.wallet),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EDE4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: AppColors.onBackground,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierTile(_RideTier tier, int index) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          // Soft mint container for selected item matching design mockup
          color: isSelected ? const Color(0xFFD7ECE6) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF3CA08D) : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Vehicle Circle Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3CA08D).withValues(alpha: 0.2)
                    : const Color(0xFFF3EDE4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tier.icon,
                color: isSelected ? const Color(0xFF236C5F) : AppColors.onBackground,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Tier Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.onSurfaceMuted,
                      ),
                      Text(
                        ' ${tier.capacity}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tier.eta,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.badge,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF236C5F)
                          : AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              tier.price,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 60), duration: 300.ms);
  }
}
