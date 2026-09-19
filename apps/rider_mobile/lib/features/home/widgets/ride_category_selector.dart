// lib/features/home/widgets/ride_category_selector.dart

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class RideCategoryItem {
  final String id;
  final String title;
  final String badge;
  final String eta;
  final IconData iconData;
  final Color badgeColor;

  const RideCategoryItem({
    required this.id,
    required this.title,
    required this.badge,
    required this.eta,
    required this.iconData,
    required this.badgeColor,
  });
}

class RideCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback? onConfirmBooking;

  const RideCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.onConfirmBooking,
  });

  static const List<RideCategoryItem> categories = [
    RideCategoryItem(
      id: 'daily_ride',
      title: 'Daily Ride',
      badge: 'Fixed Rate',
      eta: '3m away',
      iconData: Icons.directions_car_rounded,
      badgeColor: Color(0xFF0058BB),
    ),
    RideCategoryItem(
      id: 'auto',
      title: 'Auto',
      badge: 'Affordable',
      eta: '1m away',
      iconData: Icons.electric_rickshaw_rounded,
      badgeColor: Color(0xFF059669),
    ),
    RideCategoryItem(
      id: 'moto',
      title: 'Moto',
      badge: 'Fastest',
      eta: '2m away',
      iconData: Icons.two_wheeler_rounded,
      badgeColor: Color(0xFFD97706),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ride with FairGO',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: Color(0xFF191C1E),
              ),
            ),
            if (onConfirmBooking != null)
              InkWell(
                onTap: onConfirmBooking,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0058BB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF0058BB),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: categories.map((cat) {
            final isSelected = cat.id == selectedCategory;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onSelectCategory(cat.id),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0F5FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0058BB)
                            : const Color(0xFFE1E2E4),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isSelected ? 0.05 : 0.02,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0058BB).withValues(alpha: 0.1)
                                    : const Color(0xFFF2F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                cat.iconData,
                                size: 22,
                                color: isSelected
                                    ? const Color(0xFF0058BB)
                                    : const Color(0xFF191C1E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cat.badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat.badge,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: cat.badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: const Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.eta,
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
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
