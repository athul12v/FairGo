// lib/features/home/widgets/saved_places_row.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class SavedPlacesRow extends StatelessWidget {
  final ValueChanged<String>? onSelectPlace;

  const SavedPlacesRow({
    super.key,
    this.onSelectPlace,
  });

  void _handlePlaceTap(BuildContext context, String title, String address) {
    if (onSelectPlace != null) {
      onSelectPlace!(title);
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
          'Saved Places',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Home Card
            Expanded(
              child: _buildPlaceCard(
                context,
                icon: Icons.home_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF0058BB),
                title: 'Home',
                address: '12th Main, Indiranagar',
              ),
            ),
            const SizedBox(width: 12),
            // Work Card
            Expanded(
              child: _buildPlaceCard(
                context,
                icon: Icons.work_rounded,
                iconBg: const Color(0xFFF3F4F6),
                iconColor: const Color(0xFF191C1E),
                title: 'Work',
                address: 'Prestige Tech Park',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return InkWell(
      onTap: () => _handlePlaceTap(context, title, address),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE1E2E4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
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
          ],
        ),
      ),
    );
  }
}
