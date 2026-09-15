// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/app_bottom_nav.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/core/widgets/fairgo_illustrations.dart';
import 'package:rider_app/features/home/providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  String _timePreference = 'Now';

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0:
              break;
            case 1:
              context.push(AppRoutes.tripHistory);
              break;
            case 2:
              context.push(AppRoutes.wallet);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting Header + Notification Bell
              _buildHeader(context, homeState),
              const SizedBox(height: 20),

              // 2. Hero Promo Banner ("Are you ready for a smooth ride?")
              _buildHeroPromoCard(context),
              const SizedBox(height: 24),

              // 3. "Explore by popular way" Category Cards
              _buildExploreSection(context),
              const SizedBox(height: 20),

              // 4. "Where to?" Destination Pill with "Now ▾" selector
              _buildDestinationBar(context),
              const SizedBox(height: 24),

              // 5. "Take a look around you" Isometric 3D City Preview
              _buildAroundYouSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<HomeState> homeState) {
    final riderName = homeState.valueOrNull?.riderName.split(' ').first ?? 'There';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi! $riderName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.onBackground,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.onBackground,
                  size: 22,
                ),
                tooltip: 'Help & Support',
                onPressed: () => context.push(AppRoutes.support),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.onBackground,
                  size: 22,
                ),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeroPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE4), // Warm sand card from design mockup
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you ready for a\nsmooth ride?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sit back, relax and enjoy the ride.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.locationPicker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(130, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ride with FairGo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            right: -10,
            bottom: -10,
            child: RetroScooterRiderIllustration(
              width: 145,
              height: 110,
              showPassenger: true,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildExploreSection(BuildContext context) {
    final categories = [
      {'title': 'Ride', 'subtitle': 'Scooter', 'icon': Icons.two_wheeler_rounded, 'route': AppRoutes.locationPicker},
      {'title': 'Car', 'subtitle': 'Cab / Sedan', 'icon': Icons.directions_car_rounded, 'route': '/booking/select-service'},
      {'title': 'Reserve', 'subtitle': 'Book ahead', 'icon': Icons.vpn_key_rounded, 'route': AppRoutes.driverHire},
      {'title': 'Delivery', 'subtitle': 'Send parcel', 'icon': Icons.local_shipping_rounded, 'route': AppRoutes.parcelBooking},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore by popular way',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              return InkWell(
                onTap: () => context.push(cat['route'] as String),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onBackground,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        cat['icon'] as IconData,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 450.ms);
  }

  Widget _buildDestinationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push(AppRoutes.locationPicker),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.onSurfaceMuted,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Where to?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 26,
            width: 1,
            color: AppColors.surfaceBorder,
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            initialValue: _timePreference,
            onSelected: (val) => setState(() => _timePreference = val),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Now', child: Text('Now')),
              const PopupMenuItem(value: 'In 15m', child: Text('In 15 min')),
              const PopupMenuItem(value: 'Later', child: Text('Schedule ride')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECE2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    size: 16,
                    color: AppColors.onBackground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timePreference,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.onBackground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildAroundYouSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Take a look around you',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
            ),
            TextButton(
              onPressed: () => context.push('/booking/select-service'),
              child: const Text(
                'View Map',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/booking/select-service'),
          child: const IsometricCityScene(
            height: 190,
            showPins: true,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }
}
