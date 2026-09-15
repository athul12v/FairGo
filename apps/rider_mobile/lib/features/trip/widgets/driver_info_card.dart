// lib/features/trip/widgets/driver_info_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/features/trip/providers/live_trip_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverInfoCard extends StatelessWidget {
  final LiveTripState trip;
  const DriverInfoCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final etaMin = (trip.etaSeconds / 60).ceil();

    return Row(
      children: [
        // Driver avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surfaceElevated,
          child: trip.driverPhotoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: trip.driverPhotoUrl!,
                    width: 56, height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  trip.driverName.isNotEmpty ? trip.driverName[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 12),

        // Driver details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    trip.driverName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                  Text(
                    trip.driverRating.toStringAsFixed(1),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${trip.vehicleModel} · ${trip.vehicleNumber}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceMuted),
              ),
              if (trip.status == 'DRIVER_EN_ROUTE' || trip.status == 'DRIVER_ASSIGNED') ...[
                const SizedBox(height: 4),
                Text(
                  'Arrives in ~$etaMin min',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),

        // Call button
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            // INTEGRATION_BOUNDARY: masked calling via telephony API
            // In production: use masked number from backend, not direct phone
            final uri = Uri.parse('tel:${trip.driverPhone}');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Icon(Icons.phone_rounded, color: AppColors.success, size: 22),
          ),
        ),

        const SizedBox(width: 8),

        // Chat button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: open in-app chat
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 22),
          ),
        ),
      ],
    );
  }
}
