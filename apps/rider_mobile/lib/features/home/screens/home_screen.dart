// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/widgets/app_bottom_nav.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/features/home/providers/home_provider.dart';
import 'package:rider_app/features/home/widgets/destination_search_card.dart';
import 'package:rider_app/features/home/widgets/home_header.dart';
import 'package:rider_app/features/home/widgets/lightweight_map_card.dart';
import 'package:rider_app/features/home/widgets/recent_destinations_list.dart';
import 'package:rider_app/features/home/widgets/ride_category_selector.dart';
import 'package:rider_app/features/home/widgets/saved_places_row.dart';
import 'package:rider_app/features/home/widgets/zero_surge_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  void _navigateToBooking() {
    try {
      context.push(AppRoutes.locationPicker);
    } catch (_) {
      // Safe fallback if route is not registered
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeProvider);
    final selectedCategory = ref.watch(selectedRideCategoryProvider);

    final riderName = homeStateAsync.valueOrNull?.riderName ?? 'Arun';
    final pickupAddress =
        homeStateAsync.valueOrNull?.pickupAddress ?? 'Indiranagar 100ft Rd, Bengaluru';
    final profilePhotoUrl = homeStateAsync.valueOrNull?.profilePhotoUrl;

    return CrossPlatformShell(
      backgroundColor: Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FairGO Branded Header & Profile Avatar
              HomeHeader(
                riderName: riderName,
                profilePhotoUrl: profilePhotoUrl,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0),

              const SizedBox(height: 16),

              // 2. Lightweight Map Canvas Card (Pulsing pickup beacon & context)
              LightweightMapCard(
                locationText: pickupAddress,
                onTap: _navigateToBooking,
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 450.ms)
                  .scale(begin: const Offset(0.98, 0.98)),

              const SizedBox(height: 16),

              // 3. Pickup Location Display + "Where to?" Search Bar & Time Selector
              DestinationSearchCard(
                pickupAddress: pickupAddress,
                onSearchDestination: _navigateToBooking,
                onChangePickup: _navigateToBooking,
              )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 450.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 22),

              // 4. Ride Categories (Daily Ride, Auto, Moto)
              RideCategorySelector(
                selectedCategory: selectedCategory,
                onSelectCategory: (catId) {
                  ref.read(selectedRideCategoryProvider.notifier).state = catId;
                },
                onConfirmBooking: _navigateToBooking,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 450.ms),

              const SizedBox(height: 22),

              // 5. Saved Places (Home, Work)
              SavedPlacesRow(
                onSelectPlace: (_) => _navigateToBooking(),
              )
                  .animate()
                  .fadeIn(delay: 260.ms, duration: 450.ms),

              const SizedBox(height: 22),

              // 6. Recent Destinations (Koramangala, Airport, MG Road)
              RecentDestinationsList(
                onSelectDestination: (_) => _navigateToBooking(),
              )
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 450.ms),

              const SizedBox(height: 22),

              // 7. FairGO Zero Surge Guarantee Banner
              ZeroSurgeBanner(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('FairGO guarantees zero surge pricing on all rides!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(delay: 380.ms, duration: 450.ms),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
