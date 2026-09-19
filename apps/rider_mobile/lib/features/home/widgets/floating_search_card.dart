// lib/features/home/widgets/floating_search_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';

class FloatingSearchCard extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onPlaceTap;

  const FloatingSearchCard({
    super.key,
    this.onSearchTap,
    this.onPlaceTap,
  });

  @override
  State<FloatingSearchCard> createState() => _FloatingSearchCardState();
}

class _FloatingSearchCardState extends State<FloatingSearchCard> {
  String _selectedTime = 'Now';

  void _triggerSearch() {
    if (widget.onSearchTap != null) {
      widget.onSearchTap!();
    } else {
      try {
        context.push(AppRoutes.locationPicker);
      } catch (_) {}
    }
  }

  void _triggerPlace(String placeName) {
    if (widget.onPlaceTap != null) {
      widget.onPlaceTap!(placeName);
    } else {
      try {
        context.push(AppRoutes.locationPicker);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Floating "Where to?" Card (Image 3 pattern)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // "Where to?" Search Button
                Expanded(
                  child: InkWell(
                    onTap: _triggerSearch,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: Color(0xFF0058BB),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Where to?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vertical Separator
                Container(
                  height: 24,
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // "Now ▾" Time Selector Pill
                PopupMenuButton<String>(
                  initialValue: _selectedTime,
                  onSelected: (val) {
                    setState(() => _selectedTime = val);
                    if (val == 'Schedule') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scheduled rides available soon in Phase 2'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
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
                        const SizedBox(width: 3),
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
          ),
        ),

        const SizedBox(height: 10),

        // 2. Horizontal Quick Action Chips (Home, Work, Saved Places) - Image 3 pattern
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Home Chip
              _buildQuickChip(
                icon: Icons.home_rounded,
                label: 'Home',
                subtitle: '12th Main',
                onTap: () => _triggerPlace('Home'),
              ),
              const SizedBox(width: 8),
              // Work Chip
              _buildQuickChip(
                icon: Icons.work_rounded,
                label: 'Work',
                subtitle: 'Tech Park',
                onTap: () => _triggerPlace('Work'),
              ),
              const SizedBox(width: 8),
              // Saved Places Chip
              _buildQuickChip(
                icon: Icons.bookmark_border_rounded,
                label: 'Saved Places',
                onTap: () => _triggerPlace('Saved Places'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF191C1E)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
