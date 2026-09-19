// lib/features/booking/widgets/route_search_card.dart
// Floating pickup & destination card with live inline typing suggestions, swap button, and "Choose on Map" action.

import 'package:flutter/material.dart';
import 'package:rider_app/features/booking/models/map_models.dart';

class RouteSearchCard extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final VoidCallback onSwap;
  final VoidCallback onChooseOnMap;
  final VoidCallback onSavedPlaces;
  final VoidCallback onSchedule;
  final ValueChanged<MapPoint> onSelectSuggestion;
  final List<MapPoint> suggestions;
  final bool isTyping;

  const RouteSearchCard({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.onSwap,
    required this.onChooseOnMap,
    required this.onSavedPlaces,
    required this.onSchedule,
    required this.onSelectSuggestion,
    required this.suggestions,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inputs with connector and swap button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Route Visual Indicator (Circle -> Line -> Square)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0058BB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0058BB).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 38,
                      color: const Color(0xFFD1D5DB),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Center Input Fields
                Expanded(
                  child: Column(
                    children: [
                      // Pickup Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: pickupController,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Current Location',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: Color(0xFF0058BB),
                          ),
                        ],
                      ),

                      const Divider(
                        height: 18,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),

                      // Destination Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: destinationController,
                              focusNode: destinationFocusNode,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Where to?',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                          ),
                          if (destinationController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                destinationController.clear();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Swap Button
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onSwap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Search Suggestions Dropdown (shown when typing)
          if (isTyping && suggestions.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              constraints: const BoxConstraints(maxHeight: 210),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 48, color: Color(0xFFF8FAFC)),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return InkWell(
                    onTap: () => onSelectSuggestion(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Color(0xFF0058BB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Quick Action Chips Row
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.map_outlined,
                  label: 'Choose on Map',
                  isPrimary: true,
                  onTap: onChooseOnMap,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Saved Places',
                  onTap: onSavedPlaces,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.schedule_rounded,
                  label: 'Schedule',
                  onTap: onSchedule,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? const Color(0xFF0058BB) : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color:
                      isPrimary ? const Color(0xFF0058BB) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
