// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Brand palette — warm terracotta & mint/sage aesthetic matching design mockup
  static const primary = Color(0xFFD95A47);       // Terracotta Coral
  static const primaryLight = Color(0xFFE87A69);  // Coral Light
  static const primaryDark = Color(0xFFC04735);   // Burnt Terracotta
  
  // Secondary / Mint accent
  static const secondary = Color(0xFF3CA08D);     // Sage / Mint
  static const secondaryLight = Color(0xFFD7ECE6);// Mint Container / Selected Chip
  static const secondaryDark = Color(0xFF236C5F);  // Dark Mint Text

  // Accent & Semantic
  static const accent = Color(0xFFE67E22);        // Warm Orange / Surge
  static const success = Color(0xFF2E7D32);       // Forest Green
  static const error = Color(0xFFD32F2F);         // Warm Red
  static const warning = Color(0xFFF57C00);       // Deep Amber
  static const info = Color(0xFF1976D2);          // Soft Blue

  // Neutrals — Warm Cream / Off-white (Light Mode default)
  static const background = Color(0xFFF8F6F1);     // Warm Cream background
  static const surface = Color(0xFFFFFFFF);        // Pure White card
  static const surfaceElevated = Color(0xFFF3EDE4);// Soft Sand surface
  static const surfaceBorder = Color(0xFFEAE4DC);  // Warm Stone border
  static const onBackground = Color(0xFF1B1D21);   // Deep Charcoal text
  static const onSurface = Color(0xFF1B1D21);
  static const onSurfaceMuted = Color(0xFF7A7E87); // Slate Muted text
  static const onSurfaceDisabled = Color(0xFFB0B4BC);

  // Dark mode neutrals
  static const backgroundDark = Color(0xFF121316);
  static const surfaceDark = Color(0xFF1C1E23);
  static const surfaceElevatedDark = Color(0xFF242730);
  static const surfaceBorderDark = Color(0xFF2F333E);
  static const onBackgroundDark = Color(0xFFF5F6F8);
  static const onSurfaceMutedDark = Color(0xFF9196A2);

  // Map markers & route polyline
  static const mapPickupPin = Color(0xFF3CA08D);
  static const mapDropPin = Color(0xFFD95A47);
  static const mapRoutePolyline = Color(0xFFD95A47);
  static const mapDriverMarker = Color(0xFF3CA08D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFDE5E4E), Color(0xFFC04735)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFFF4ECE2), Color(0xFFEFE6D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD95A47), Color(0xFFE67E22)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryLight,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.onSurface,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackground,
          letterSpacing: -0.3,
        ),
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: AppColors.onBackground),
        displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppColors.onBackground),
        displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: AppColors.onBackground),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppColors.onBackground),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.onBackground),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.onBackground),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.onBackground),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: AppColors.onBackground),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onBackground, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceMuted, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceMuted),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.onSurfaceMuted),
      ),

      // Elevated Button (Terracotta Pill)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onBackground,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 15,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      secondaryContainer: Color(0xFF1F3D37),
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.onBackgroundDark,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.onBackgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundDark,
          letterSpacing: -0.3,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: AppColors.onBackgroundDark),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppColors.onBackgroundDark),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.onBackgroundDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.onBackgroundDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: AppColors.onBackgroundDark),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackgroundDark),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onBackgroundDark, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceMutedDark, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceMutedDark),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorderDark,
        thickness: 1,
      ),
    );
  }
}
