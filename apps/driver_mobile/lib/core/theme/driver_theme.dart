// lib/core/theme/driver_theme.dart — Driver App uses teal/emerald brand (earner-focused)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriverColors {
  DriverColors._();

  // Brand: teal/emerald (earner-positive, money-green psychology)
  static const primary = Color(0xFF10B981);       // Emerald-500
  static const primaryLight = Color(0xFF34D399);  // Emerald-400
  static const primaryDark = Color(0xFF065F46);   // Emerald-900
  static const secondary = Color(0xFF06B6D4);     // Cyan-500
  static const accent = Color(0xFFF59E0B);        // Amber — earnings highlight

  // Online/offline status
  static const online = Color(0xFF10B981);
  static const offline = Color(0xFF6B7280);
  static const onTrip = Color(0xFF3B82F6);

  // Semantic
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // Neutrals
  static const background = Color(0xFF0A0F0E);    // Slightly green-tinted dark
  static const surface = Color(0xFF141A19);
  static const surfaceElevated = Color(0xFF1E2725);
  static const surfaceBorder = Color(0xFF2A3530);
  static const onBackground = Color(0xFFF0FDF9);
  static const onSurface = Color(0xFFD1FAE5);
  static const onSurfaceMuted = Color(0xFF6EE7B7);
  static const onSurfaceDisabled = Color(0xFF374151);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient earningsGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class DriverTheme {
  DriverTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: DriverColors.primary,
      primaryContainer: DriverColors.primaryDark,
      secondary: DriverColors.secondary,
      surface: DriverColors.surface,
      error: DriverColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: DriverColors.onSurface,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DriverColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: DriverColors.background,
        foregroundColor: DriverColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DriverColors.onBackground,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: DriverColors.onBackground),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: DriverColors.onBackground),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: DriverColors.onBackground),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: DriverColors.onBackground),
        bodyLarge: TextStyle(fontSize: 16, color: DriverColors.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: DriverColors.onSurface),
        bodySmall: TextStyle(fontSize: 12, color: DriverColors.onSurfaceMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DriverColors.onBackground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DriverColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DriverColors.surfaceElevated,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: DriverColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DriverColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DriverColors.surface,
        selectedItemColor: DriverColors.primary,
        unselectedItemColor: DriverColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DriverColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: DriverColors.surfaceBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DriverColors.surfaceElevated,
        contentTextStyle: const TextStyle(fontFamily: 'Inter', color: DriverColors.onBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
