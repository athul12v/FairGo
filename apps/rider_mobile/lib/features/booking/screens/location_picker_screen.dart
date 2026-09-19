// lib/features/booking/screens/location_picker_screen.dart
// Modern destination selection screen featuring interactive OpenStreetMap,
// floating route search card with live suggestions, saved places, and vehicle markers.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:rider_app/core/router/app_router.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/core/widgets/cross_platform_shell.dart';
import 'package:rider_app/features/booking/models/map_models.dart';
import 'package:rider_app/features/booking/widgets/map_picker_view.dart';
import 'package:rider_app/features/booking/widgets/recent_destinations_sheet.dart';
import 'package:rider_app/features/booking/widgets/route_search_card.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _pickupController =
      TextEditingController(text: 'Current Location • Indiranagar 100ft Rd');
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();

  // Primary Locations
  MapPoint _pickupPoint = const MapPoint(
    latitude: 12.9716,
    longitude: 77.5946,
    label: 'Current Location',
    address: 'Indiranagar 100ft Rd',
  );

  MapPoint? _destinationPoint;
  bool _isPickingOnMap = false;
  bool _isTyping = false;
  List<MapPoint> _filteredSuggestions = [];

  // Realistic nearby vehicles (cars, autos, bikes)
  final List<NearbyVehicle> _nearbyVehicles = const [
    NearbyVehicle(
      id: 'v_car_1',
      latitude: 12.9738,
      longitude: 77.5962,
      bearingDegrees: 45,
      type: VehicleType.sedan,
    ),
    NearbyVehicle(
      id: 'v_auto_1',
      latitude: 12.9702,
      longitude: 77.5925,
      bearingDegrees: 180,
      type: VehicleType.auto,
    ),
    NearbyVehicle(
      id: 'v_bike_1',
      latitude: 12.9745,
      longitude: 77.5918,
      bearingDegrees: 90,
      type: VehicleType.bike,
    ),
    NearbyVehicle(
      id: 'v_car_2',
      latitude: 12.9691,
      longitude: 77.5975,
      bearingDegrees: 310,
      type: VehicleType.premium,
    ),
    NearbyVehicle(
      id: 'v_auto_2',
      latitude: 12.9725,
      longitude: 77.5985,
      bearingDegrees: 120,
      type: VehicleType.auto,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(_onDestinationTextChanged);
  }

  void _onDestinationTextChanged() {
    final text = _destinationController.text.trim().toLowerCase();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _filteredSuggestions = [];
        });
      }
      return;
    }

    final List<MapPoint> allCandidates = [
      ...RecentDestinationsSheet.savedPlaces.map((e) => e.point),
      ...RecentDestinationsSheet.destinations.map((e) => e.point),
    ];

    final matches = allCandidates.where((p) {
      final inLabel = p.label.toLowerCase().contains(text);
      final inAddress = p.address?.toLowerCase().contains(text) ?? false;
      return inLabel || inAddress;
    }).toList();

    if (mounted) {
      setState(() {
        _isTyping = true;
        _filteredSuggestions = matches;
      });
    }
  }

  void _onSelectDestination(MapPoint point) {
    setState(() {
      _destinationPoint = point;
      _destinationController.text = point.label;
      _isTyping = false;
      _isPickingOnMap = false;
    });

    _navigateToFareEstimate(point);
  }

  void _navigateToFareEstimate(MapPoint destination) {
    // Automatically transition to Fare Estimate screen
    final extra = FareEstimateExtra(
      serviceType: 'ride',
      vehicleType: 'daily',
      pickupLat: _pickupPoint.latitude,
      pickupLon: _pickupPoint.longitude,
      pickupAddress: _pickupPoint.label,
      dropLat: destination.latitude,
      dropLon: destination.longitude,
      dropAddress: destination.label,
    );

    context.push(AppRoutes.fareEstimate, extra: extra);
  }

  void _swapLocations() {
    if (_destinationPoint == null) return;
    setState(() {
      final tempPoint = _pickupPoint;
      _pickupPoint = _destinationPoint!;
      _destinationPoint = tempPoint;

      final tempText = _pickupController.text;
      _pickupController.text = _destinationController.text;
      _destinationController.text = tempText;
    });
  }

  void _enableChooseOnMap() {
    setState(() {
      _isPickingOnMap = true;
      _isTyping = false;
      _destinationFocusNode.unfocus();
    });
  }

  void _confirmPinnedLocation() {
    final center = _mapController.camera.center;
    final pinned = MapPoint(
      latitude: center.latitude,
      longitude: center.longitude,
      label: 'Pinned Location',
      address:
          'Lat ${center.latitude.toStringAsFixed(4)}, Lng ${center.longitude.toStringAsFixed(4)}',
    );
    _onSelectDestination(pinned);
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrossPlatformShell(
      backgroundColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Layer 0: Modular OpenStreetMap with markers & vehicles
            Positioned.fill(
              child: MapPickerView(
                controller: _mapController,
                pickup: _pickupPoint,
                destination: _destinationPoint,
                nearbyVehicles: _nearbyVehicles,
                isPickingOnMap: _isPickingOnMap,
                onLocationPinned: (point) {
                  _onSelectDestination(point);
                },
              ),
            ),

            // Layer 1: Floating Header & RouteSearchCard (SafeArea Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Bar with Back Button & Title
                      Row(
                        children: [
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.12),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Set Route',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Floating RouteSearchCard
                      RouteSearchCard(
                        pickupController: _pickupController,
                        destinationController: _destinationController,
                        destinationFocusNode: _destinationFocusNode,
                        onSwap: _swapLocations,
                        onChooseOnMap: _enableChooseOnMap,
                        onSavedPlaces: () {
                          // Scroll sheet up or focus
                          _destinationFocusNode.unfocus();
                        },
                        onSchedule: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Scheduling ride for later...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        onSelectSuggestion: _onSelectDestination,
                        suggestions: _filteredSuggestions,
                        isTyping: _isTyping,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 2: "Choose on Map" Pin Confirmation Pill (when active)
            if (_isPickingOnMap)
              Positioned(
                left: 20,
                right: 20,
                bottom: 36,
                child: SafeArea(
                  child: Row(
                    children: [
                      // Cancel Button
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isPickingOnMap = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF0F172A),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm Pinned Location Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmPinnedLocation,
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Confirm Pinned Location',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0058BB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Layer 3: Draggable Bottom Sheet (when NOT in map-picking mode)
            else if (!_isTyping)
              DraggableScrollableSheet(
                initialChildSize: 0.42,
                minChildSize: 0.22,
                maxChildSize: 0.70,
                builder: (context, scrollController) {
                  return RecentDestinationsSheet(
                    scrollController: scrollController,
                    onSelectDestination: _onSelectDestination,
                    onManageSavedPlaces: () {
                      context.push(AppRoutes.savedPlaces);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
