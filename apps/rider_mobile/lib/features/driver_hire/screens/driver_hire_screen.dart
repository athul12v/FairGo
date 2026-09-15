// lib/features/driver_hire/screens/driver_hire_screen.dart
// "Reservation" & "Car details" screen matching the reference design with car illustration, specs, features, add-ons, and terracotta Continue button

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/core/widgets/fairgo_illustrations.dart';

class DriverHireScreen extends StatefulWidget {
  const DriverHireScreen({super.key});

  @override
  State<DriverHireScreen> createState() => _DriverHireScreenState();
}

class _DriverHireScreenState extends State<DriverHireScreen> {
  final Map<String, int> _addonCounts = {
    'Toddler seat': 1,
    'Booster seat': 0,
    'Pet friendly': 0,
  };

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
          'Reservation',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildBottomBar(context),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Car Illustration & Model Subtitle
              Center(
                child: const RetroCoupeCarIllustration(
                  width: 320,
                  height: 120,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Chevrolet Malibu or similar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Specs Row (Seats, Luggage, Doors, Gearbox)
              _buildSpecsRow(),
              const SizedBox(height: 24),

              // 3. Features Section
              Text(
                'Features',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
              ),
              const SizedBox(height: 12),
              _buildFeatureTile(
                icon: Icons.alt_route_rounded,
                title: 'Unlimited mileage',
              ),
              const SizedBox(height: 10),
              _buildFeatureTile(
                icon: Icons.location_on_rounded,
                title: 'In-city pickup',
              ),
              const SizedBox(height: 24),

              // 4. Add-ons Section (Horizontal scroll cards)
              Text(
                'Add-ons',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
              ),
              const SizedBox(height: 12),
              _buildAddonsRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSpecItem(Icons.person_outline_rounded, '4 seats'),
        _buildSpecItem(Icons.luggage_outlined, '2 bags'),
        _buildSpecItem(Icons.door_back_door_outlined, '4 doors'),
        _buildSpecItem(Icons.settings_suggest_outlined, 'Automatic'),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String label) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.onBackground),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onBackground),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsRow() {
    final addons = [
      {'name': 'Toddler seat', 'icon': Icons.child_care_rounded},
      {'name': 'Booster seat', 'icon': Icons.chair_alt_rounded},
      {'name': 'Pet friendly', 'icon': Icons.pets_rounded},
    ];

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: addons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = addons[index];
          final name = item['name'] as String;
          final count = _addonCounts[name] ?? 0;

          return Container(
            width: 108,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDE4), // Warm sand card
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item['icon'] as IconData, size: 26, color: AppColors.onBackground),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _addonCounts[name] = (_addonCounts[name] ?? 0) + 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, size: 14, color: AppColors.onBackground),
                      ),
                    ),
                  ],
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count selected',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$103.90',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '\$54.67 per day',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chauffeur booked successfully!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 52),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
