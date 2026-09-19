// lib/features/home/widgets/destination_search_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class DestinationSearchCard extends StatefulWidget {
  final String pickupAddress;
  final VoidCallback? onChangePickup;
  final VoidCallback? onSearchDestination;

  const DestinationSearchCard({
    super.key,
    required this.pickupAddress,
    this.onChangePickup,
    this.onSearchDestination,
  });

  @override
  State<DestinationSearchCard> createState() => _DestinationSearchCardState();
}

class _DestinationSearchCardState extends State<DestinationSearchCard> {
  String _selectedTime = 'Now';

  void _navigateToDestinationSearch() {
    if (widget.onSearchDestination != null) {
      widget.onSearchDestination!();
    } else {
      try {
        context.push(AppRoutes.locationPicker);
      } catch (_) {
        // Safe fallback if route is intercepted
      }
    }
  }

  void _handleChangePickup() {
    if (widget.onChangePickup != null) {
      widget.onChangePickup!();
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E2E4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pickup Location Row
          InkWell(
            onTap: _handleChangePickup,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // Emerald green
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Pickup: ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                          TextSpan(
                            text: widget.pickupAddress,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Change',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0058BB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F3)),
          ),

          // 2. "Where to?" Search Bar & Time Selector
          Row(
            children: [
              // Search Input Trigger
              Expanded(
                child: InkWell(
                  onTap: _navigateToDestinationSearch,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF191C1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Where to?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Time Selector Chip (Now / Schedule UI)
              PopupMenuButton<String>(
                initialValue: _selectedTime,
                onSelected: (val) {
                  setState(() => _selectedTime = val);
                  if (val == 'Schedule') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheduled rides will be available in Phase 2'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Now',
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF0058BB)),
                        SizedBox(width: 8),
                        Text('Now (Instant)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'In 15m',
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: Color(0xFF191C1E)),
                        SizedBox(width: 8),
                        Text('In 15 mins'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Schedule',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF191C1E)),
                        SizedBox(width: 8),
                        Text('Schedule ride'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF191C1E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedTime,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
