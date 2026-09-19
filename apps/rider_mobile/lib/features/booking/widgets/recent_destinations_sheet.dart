// lib/features/booking/widgets/recent_destinations_sheet.dart
// Bottom sheet presenting Saved Places (Home, Work, Favorites) and generic destination categories.

import 'package:flutter/material.dart';
import 'package:rider_app/features/booking/models/map_models.dart';

class SavedPlaceItem {
  final String title;
  final String address;
  final String eta;
  final IconData icon;
  final MapPoint point;

  const SavedPlaceItem({
    required this.title,
    required this.address,
    required this.eta,
    required this.icon,
    required this.point,
  });
}

class DestinationItem {
  final String title;
  final String subtitle;
  final String distance;
  final String eta;
  final IconData icon;
  final MapPoint point;

  const DestinationItem({
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.eta,
    required this.icon,
    required this.point,
  });
}

class RecentDestinationsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<MapPoint> onSelectDestination;
  final VoidCallback? onManageSavedPlaces;

  const RecentDestinationsSheet({
    super.key,
    required this.scrollController,
    required this.onSelectDestination,
    this.onManageSavedPlaces,
  });

  static const List<SavedPlaceItem> savedPlaces = [
    SavedPlaceItem(
      title: 'Home',
      address: '42 Greenfield Avenue',
      eta: '15m',
      icon: Icons.home_rounded,
      point: MapPoint(
        latitude: 12.9716,
        longitude: 77.5946,
        label: 'Home',
        address: '42 Greenfield Avenue',
      ),
    ),
    SavedPlaceItem(
      title: 'Work',
      address: 'Apex Business District',
      eta: '22m',
      icon: Icons.work_rounded,
      point: MapPoint(
        latitude: 12.9352,
        longitude: 77.6245,
        label: 'Work',
        address: 'Apex Business District',
      ),
    ),
    SavedPlaceItem(
      title: 'Favorites',
      address: 'Grand Central Club',
      eta: '10m',
      icon: Icons.star_rounded,
      point: MapPoint(
        latitude: 12.9815,
        longitude: 77.6105,
        label: 'Favorites',
        address: 'Grand Central Club',
      ),
    ),
  ];

  static const List<DestinationItem> destinations = [
    DestinationItem(
      title: 'International Airport',
      subtitle: 'Terminal 1 & 2 Departures',
      distance: '32 km',
      eta: '35 min',
      icon: Icons.flight_takeoff_rounded,
      point: MapPoint(
        latitude: 13.1986,
        longitude: 77.7066,
        label: 'International Airport',
        address: 'Terminal 1 & 2 Departures',
      ),
    ),
    DestinationItem(
      title: 'Central Railway Station',
      subtitle: 'Main Concourse & Platform 1',
      distance: '12 km',
      eta: '20 min',
      icon: Icons.train_rounded,
      point: MapPoint(
        latitude: 12.9784,
        longitude: 77.5694,
        label: 'Central Railway Station',
        address: 'Main Concourse & Platform 1',
      ),
    ),
    DestinationItem(
      title: 'City Center Plaza',
      subtitle: 'Grand Central Square & Promenade',
      distance: '5.4 km',
      eta: '14 min',
      icon: Icons.location_city_rounded,
      point: MapPoint(
        latitude: 12.9734,
        longitude: 77.6075,
        label: 'City Center Plaza',
        address: 'Grand Central Square & Promenade',
      ),
    ),
    DestinationItem(
      title: 'Grand Metro Mall',
      subtitle: 'Fashion Avenue & Food Court',
      distance: '8.2 km',
      eta: '18 min',
      icon: Icons.local_mall_rounded,
      point: MapPoint(
        latitude: 12.9928,
        longitude: 77.6833,
        label: 'Grand Metro Mall',
        address: 'Fashion Avenue & Food Court',
      ),
    ),
    DestinationItem(
      title: 'City General Hospital',
      subtitle: 'Main Emergency & OPD Complex',
      distance: '6.5 km',
      eta: '15 min',
      icon: Icons.local_hospital_rounded,
      point: MapPoint(
        latitude: 12.9611,
        longitude: 77.5857,
        label: 'City General Hospital',
        address: 'Main Emergency & OPD Complex',
      ),
    ),
    DestinationItem(
      title: 'Infinity Tech Park',
      subtitle: 'Innovation Boulevard, Tower 4',
      distance: '14.5 km',
      eta: '25 min',
      icon: Icons.business_rounded,
      point: MapPoint(
        latitude: 13.0475,
        longitude: 77.6200,
        label: 'Infinity Tech Park',
        address: 'Innovation Boulevard, Tower 4',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Saved Places Section (Above Recent Destinations)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Places',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              if (onManageSavedPlaces != null)
                GestureDetector(
                  onTap: onManageSavedPlaces,
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0058BB),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Saved Places Cards Row
          Row(
            children: savedPlaces.map((place) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => onSelectDestination(place.point),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Icon(
                                    place.icon,
                                    size: 16,
                                    color: const Color(0xFF0058BB),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    place.eta,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0058BB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              place.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.address,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 2. Recent Destinations Section
          const Text(
            'Recent Destinations',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Destinations List
          for (final item in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onSelectDestination(item.point),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: const Color(0xFF0058BB),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.eta,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.distance,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
