// lib/features/booking/screens/location_picker_screen.dart
// Location picker screen with pickup & destination search, saved places, and Terracotta CTA

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/core/widgets/fairgo_illustrations.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _pickupController =
      TextEditingController(text: 'Current Location (Indiranagar 100ft Rd)');
  final TextEditingController _destinationController = TextEditingController();

  final List<Map<String, dynamic>> _recentPlaces = [
    {
      'title': 'Koramangala 5th Block',
      'subtitle': '80 Feet Rd, Bengaluru',
      'distance': '4.2 km',
      'icon': Icons.history_rounded,
    },
    {
      'title': 'Kempegowda Int\'l Airport (BLR)',
      'subtitle': 'Terminal 1 & 2 Departure',
      'distance': '38 km',
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'title': 'MG Road Metro Station',
      'subtitle': 'Mahatma Gandhi Rd, Ashok Nagar',
      'distance': '5.8 km',
      'icon': Icons.subway_rounded,
    },
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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
          'Set Route',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: false,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inputs card (Pickup & Destination)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _pickupController,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onBackground,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Pickup point',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1, color: AppColors.surfaceBorder),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            autofocus: true,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onBackground,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Where to? (Destination)',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 20),

              // Mini Isometric map preview
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const IsometricCityScene(
                  height: 120,
                  showPins: true,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Recent Destinations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
              ),
              const SizedBox(height: 12),

              // Recent places list
              for (final place in _recentPlaces)
                InkWell(
                  onTap: () {
                    _destinationController.text = place['title'] as String;
                    context.push('/booking/fare-estimate');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EDE4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            place['icon'] as IconData,
                            size: 20,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place['title'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place['subtitle'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          place['distance'] as String,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => context.push('/booking/fare-estimate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirm Route',
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
      ),
    );
  }
}
