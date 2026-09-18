import 'package:flutter/material.dart';

class TripSummaryScreen extends StatelessWidget {
  final String tripId;
  const TripSummaryScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
      body: Center(child: Text('Trip Summary for: $tripId')),
    );
  }
}
