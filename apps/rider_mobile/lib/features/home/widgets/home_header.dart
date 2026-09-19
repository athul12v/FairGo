// lib/features/home/widgets/home_header.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final String riderName;
  final String? profilePhotoUrl;

  const HomeHeader({
    super.key,
    required this.riderName,
    this.profilePhotoUrl,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = riderName.trim().isNotEmpty ? riderName.split(' ').first : 'Rider';
    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // FairGO Brand Mark & Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058BB),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fair',
                        style: TextStyle(
                          color: Color(0xFF191C1E),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'GO',
                        style: TextStyle(
                          color: Color(0xFF0058BB),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' •',
                        style: TextStyle(
                          color: Color(0xFF1471E6),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_getGreeting()}, $displayName',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),

        // Profile Avatar Button
        InkWell(
          onTap: () => context.push(AppRoutes.profile),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE1E2E4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profilePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackAvatar(initialLetter),
                    ),
                  )
                : _buildFallbackAvatar(initialLetter),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(String initialLetter) {
    return Center(
      child: Text(
        initialLetter,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0058BB),
        ),
      ),
    );
  }
}
