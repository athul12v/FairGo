import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/providers/auth_provider.dart';

// Screens
import 'package:rider_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:rider_app/features/auth/screens/phone_entry_screen.dart';
import 'package:rider_app/features/auth/screens/otp_verification_screen.dart';
import 'package:rider_app/features/auth/screens/profile_setup_screen.dart';
import 'package:rider_app/features/home/screens/home_screen.dart';
import 'package:rider_app/features/booking/screens/service_selection_screen.dart';
import 'package:rider_app/features/booking/screens/location_picker_screen.dart';
import 'package:rider_app/features/booking/screens/fare_estimate_screen.dart';
import 'package:rider_app/features/booking/screens/searching_driver_screen.dart';
import 'package:rider_app/features/trip/screens/live_trip_screen.dart';
import 'package:rider_app/features/trip/screens/trip_summary_screen.dart';
import 'package:rider_app/features/trip/screens/rate_driver_screen.dart';
import 'package:rider_app/features/trip_history/screens/trip_history_screen.dart';
import 'package:rider_app/features/trip_history/screens/trip_detail_screen.dart';
import 'package:rider_app/features/wallet/screens/wallet_screen.dart';
import 'package:rider_app/features/wallet/screens/topup_screen.dart';
import 'package:rider_app/features/profile/screens/profile_screen.dart';
import 'package:rider_app/features/profile/screens/saved_places_screen.dart';
import 'package:rider_app/features/profile/screens/emergency_contacts_screen.dart';
import 'package:rider_app/features/safety/screens/sos_screen.dart';
import 'package:rider_app/features/support/screens/support_screen.dart';
import 'package:rider_app/features/parcel/screens/parcel_booking_screen.dart';
import 'package:rider_app/features/driver_hire/screens/driver_hire_screen.dart';
import 'package:rider_app/features/scheduled/screens/scheduled_rides_screen.dart';
import 'package:rider_app/features/corporate/screens/corporate_screen.dart';
import 'package:rider_app/features/notifications/screens/notifications_screen.dart';

// Named routes
class AppRoutes {
  static const onboarding = '/onboarding';
  static const phoneEntry = '/auth/phone';
  static const otpVerification = '/auth/otp';
  static const profileSetup = '/auth/profile';
  static const home = '/';
  static const serviceSelection = '/booking/select-service';
  static const locationPicker = '/booking/location';
  static const fareEstimate = '/booking/fare';
  static const searchingDriver = '/booking/searching';
  static const liveTrip = '/trip/live';
  static const tripSummary = '/trip/summary/:tripId';
  static const rateDriver = '/trip/rate/:tripId';
  static const tripHistory = '/trips';
  static const tripDetail = '/trips/:tripId';
  static const wallet = '/wallet';
  static const topup = '/wallet/topup';
  static const profile = '/profile';
  static const savedPlaces = '/profile/places';
  static const emergencyContacts = '/profile/emergency';
  static const sos = '/safety/sos';
  static const support = '/support';
  static const parcelBooking = '/parcel';
  static const driverHire = '/driver-hire';
  static const scheduledRides = '/scheduled';
  static const corporate = '/corporate';
  static const notifications = '/notifications';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isOnboarded = authState.valueOrNull?.isOnboarded ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isOnboarded && !isAuthRoute) {
        return AppRoutes.onboarding;
      }
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.phoneEntry;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneEntry,
        builder: (_, __) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (_, state) => OtpVerificationScreen(
          phone: state.extra as String,
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'booking/select-service',
            builder: (_, __) => const ServiceSelectionScreen(),
          ),
          GoRoute(
            path: 'booking/location',
            builder: (_, __) => const LocationPickerScreen(),
          ),
          GoRoute(
            path: 'booking/fare',
            builder: (_, state) => FareEstimateScreen(
              extra: state.extra as FareEstimateExtra,
            ),
          ),
          GoRoute(
            path: 'booking/searching',
            builder: (_, state) => SearchingDriverScreen(
              tripId: state.extra as String,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.liveTrip,
        builder: (_, state) => LiveTripScreen(tripId: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.tripSummary,
        builder: (_, state) => TripSummaryScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: AppRoutes.rateDriver,
        builder: (_, state) => RateDriverScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: AppRoutes.tripHistory,
        builder: (_, __) => const TripHistoryScreen(),
        routes: [
          GoRoute(
            path: ':tripId',
            builder: (_, state) => TripDetailScreen(tripId: state.pathParameters['tripId']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.wallet, builder: (_, __) => const WalletScreen()),
      GoRoute(path: AppRoutes.topup, builder: (_, __) => const TopupScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.savedPlaces, builder: (_, __) => const SavedPlacesScreen()),
      GoRoute(path: AppRoutes.emergencyContacts, builder: (_, __) => const EmergencyContactsScreen()),
      GoRoute(path: AppRoutes.sos, builder: (_, __) => const SosScreen()),
      GoRoute(path: AppRoutes.support, builder: (_, __) => const SupportScreen()),
      GoRoute(path: AppRoutes.parcelBooking, builder: (_, __) => const ParcelBookingScreen()),
      GoRoute(path: AppRoutes.driverHire, builder: (_, __) => const DriverHireScreen()),
      GoRoute(path: AppRoutes.scheduledRides, builder: (_, __) => const ScheduledRidesScreen()),
      GoRoute(path: AppRoutes.corporate, builder: (_, __) => const CorporateScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Center(
        child: Text(
          'Page not found',
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
      ),
    ),
  );
});

// Extra types for route data
class FareEstimateExtra {
  final String serviceType;
  final String vehicleType;
  final double pickupLat;
  final double pickupLon;
  final String pickupAddress;
  final double dropLat;
  final double dropLon;
  final String dropAddress;

  const FareEstimateExtra({
    required this.serviceType,
    required this.vehicleType,
    required this.pickupLat,
    required this.pickupLon,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLon,
    required this.dropAddress,
  });
}
