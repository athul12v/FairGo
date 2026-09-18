import 'package:flutter/material.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Detail')),
      body: Center(child: Text('Trip Detail for: $tripId')),
    );
  }
}
