// lib/core/widgets/cross_platform_shell.dart

import 'package:flutter/material.dart';
import 'package:rider_app/core/theme/app_theme.dart';

enum DeviceType { compact, tablet, desktop }

class DeviceBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double maxContentWidth = 480;
  static const double maxSplitContentWidth = 1100;
}

class CrossPlatformShell extends StatelessWidget {
  final Widget child;
  final Widget? sidePanel;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool enableMaxConstraint;
  final double maxWidth;

  const CrossPlatformShell({
    super.key,
    required this.child,
    this.sidePanel,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.enableMaxConstraint = true,
    this.maxWidth = DeviceBreakpoints.maxContentWidth,
  });

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= DeviceBreakpoints.desktop) return DeviceType.desktop;
    if (width >= DeviceBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.compact;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < DeviceBreakpoints.tablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= DeviceBreakpoints.tablet && width < DeviceBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= DeviceBreakpoints.desktop;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerBg = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.background);

    // On compact mobile: full-screen native experience
    if (screenWidth < DeviceBreakpoints.tablet || !enableMaxConstraint) {
      return Scaffold(
        backgroundColor: outerBg,
        appBar: appBar,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    // On Desktop with split side-panel provided:
    if (screenWidth >= DeviceBreakpoints.desktop && sidePanel != null) {
      return Scaffold(
        backgroundColor: outerBg,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: DeviceBreakpoints.maxSplitContentWidth,
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: sidePanel!,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Scaffold(
                      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                      appBar: appBar,
                      body: child,
                      bottomNavigationBar: bottomNavigationBar,
                      floatingActionButton: floatingActionButton,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // On Tablet or Desktop single-column: Centered device frame with soft ambient elevation
    return Scaffold(
      backgroundColor: outerBg,
      body: Center(
        child: Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppColors.surfaceBorderDark : AppColors.surfaceBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            appBar: appBar,
            body: child,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
          ),
        ),
      ),
    );
  }
}
