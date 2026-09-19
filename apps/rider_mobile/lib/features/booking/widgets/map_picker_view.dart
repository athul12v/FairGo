// lib/features/booking/widgets/map_picker_view.dart
// Modular Map component wrapping flutter_map with OpenStreetMap tiles.
// Decoupled via MapPoint & NearbyVehicle so it can be swapped for Google Maps later.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:rider_app/features/booking/models/map_models.dart';

class MapPickerView extends StatefulWidget {
  final MapPoint pickup;
  final MapPoint? destination;
  final List<NearbyVehicle> nearbyVehicles;
  final bool isPickingOnMap;
  final ValueChanged<MapPoint>? onLocationPinned;
  final VoidCallback? onRecenter;
  final MapController? controller;

  const MapPickerView({
    super.key,
    required this.pickup,
    this.destination,
    this.nearbyVehicles = const [],
    this.isPickingOnMap = false,
    this.onLocationPinned,
    this.onRecenter,
    this.controller,
  });

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MapPickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destination != null &&
        widget.destination != oldWidget.destination) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.destination == null) return;
    try {
      final bounds = LatLngBounds(
        LatLng(widget.pickup.latitude, widget.pickup.longitude),
        LatLng(widget.destination!.latitude, widget.destination!.longitude),
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 220,
            bottom: 280,
            left: 50,
            right: 50,
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.controller == null) {
      _mapController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupLatLng =
        LatLng(widget.pickup.latitude, widget.pickup.longitude);
    final destinationLatLng = widget.destination != null
        ? LatLng(widget.destination!.latitude, widget.destination!.longitude)
        : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pickupLatLng,
            initialZoom: 14.5,
            minZoom: 4.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              if (widget.isPickingOnMap && widget.onLocationPinned != null) {
                widget.onLocationPinned!(
                  MapPoint(
                    latitude: point.latitude,
                    longitude: point.longitude,
                    label: 'Pinned Location',
                    address:
                        '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                  ),
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fairgo.rider_mobile',
              maxZoom: 19,
            ),

            // Polyline if destination is set
            if (destinationLatLng != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [pickupLatLng, destinationLatLng],
                    strokeWidth: 4.5,
                    color: const Color(0xFF0058BB),
                  ),
                ],
              ),

            // Vehicle markers
            MarkerLayer(
              markers: [
                // Nearby vehicles
                for (final vehicle in widget.nearbyVehicles)
                  Marker(
                    point: LatLng(vehicle.latitude, vehicle.longitude),
                    width: 38,
                    height: 38,
                    child: Transform.rotate(
                      angle: vehicle.bearingDegrees * (3.14159265359 / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: vehicle.color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            vehicle.icon,
                            size: 20,
                            color: vehicle.color,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Pickup Marker (Pulsing Halo Beacon)
                Marker(
                  point: pickupLatLng,
                  width: 50,
                  height: 50,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 22 + (_pulseController.value * 28),
                            height: 22 + (_pulseController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0058BB).withValues(
                                alpha: (1.0 - _pulseController.value) * 0.45,
                              ),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0058BB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Destination Marker (if chosen)
                if (destinationLatLng != null)
                  Marker(
                    point: destinationLatLng,
                    width: 44,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const CustomPaint(
                          size: Size(12, 6),
                          painter: _TrianglePointerPainter(
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Center Pin Reticle when in "Choose on Map" mode
        if (widget.isPickingOnMap)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Drag map to position pin',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.location_pin,
                  size: 46,
                  color: Color(0xFF0058BB),
                ),
                const SizedBox(height: 38), // Offset for pin point
              ],
            ),
          ),

        // Recenter GPS FAB
        Positioned(
          right: 16,
          bottom: widget.isPickingOnMap ? 100 : 260,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _mapController.move(pickupLatLng, 15.0);
                if (widget.onRecenter != null) widget.onRecenter!();
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF1E293B),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;
  const _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
