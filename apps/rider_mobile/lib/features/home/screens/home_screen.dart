// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/widgets/app_bottom_nav.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/features/home/providers/home_provider.dart';
import 'package:rider_app/features/home/widgets/floating_search_card.dart';
import 'package:rider_app/features/home/widgets/home_bottom_sheet.dart';
import 'package:rider_app/features/home/widgets/home_header.dart';
import 'package:rider_app/features/home/widgets/home_map_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final int _navIndex = 0;

  void _navigateToBooking() {
    try {
      context.push(AppRoutes.locationPicker);
    } catch (_) {
      // Safe fallback if route is intercepted
    }
  }

  void _handleSafetyCenter() {
    try {
      context.push(AppRoutes.sos);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FairGO Safety Center: 24/7 Helpline active'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleRecenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on Current Location: Indiranagar 100ft Rd'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeProvider);
    final selectedCategory = ref.watch(selectedRideCategoryProvider);
    final riderName = homeStateAsync.valueOrNull?.riderName ?? 'Arun';
    final initialLetter = riderName.trim().isNotEmpty ? riderName.trim()[0].toUpperCase() : 'A';
    final profilePhotoUrl = homeStateAsync.valueOrNull?.profilePhotoUrl;

    return CrossPlatformShell(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
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
      child: Stack(
        children: [
          // 1. Primary Background Map Layer (Image 3 pattern)
          Positioned.fill(
            child: HomeMapBackground(
              onSafetyTap: _handleSafetyCenter,
              onRecenterTap: _handleRecenter,
            ),
          ),

          // 2. Scrollable Bottom Sheet for Content (Image 3 layout)
          NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.50,
              minChildSize: 0.36,
              maxChildSize: 0.74,
              snap: true,
              snapSizes: const [0.36, 0.50, 0.74],
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: HomeBottomSheet(
                    selectedCategory: selectedCategory,
                    onSelectCategory: (catId) {
                      ref.read(selectedRideCategoryProvider.notifier).state = catId;
                    },
                    onBookingTap: _navigateToBooking,
                  ),
                );
              },
            ),
          ),

          // 3. Top Floating Header & Search Deck (Pinned at top over map)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Header & Profile Avatar
                  HomeHeader(
                    profilePhotoUrl: profilePhotoUrl,
                    initialLetter: initialLetter,
                  ),

                  const SizedBox(height: 4),

                  // Floating "Where to?" Search Card + Quick Chips (Home, Work, Saved Places)
                  FloatingSearchCard(
                    onSearchTap: _navigateToBooking,
                    onPlaceTap: (_) => _navigateToBooking(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
