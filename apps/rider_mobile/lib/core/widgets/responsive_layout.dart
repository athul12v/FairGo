// lib/core/widgets/responsive_layout.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Screen classification based on Material 3 responsive design specifications
enum WindowSizeClass {
  /// Phones in portrait (< 600dp)
  compact,

  /// Tablets, Foldable unfolded cover/main screen, Phones in landscape (600dp - 840dp)
  medium,

  /// Tablets, Foldable main screens, Desktop (> 840dp)
  expanded,
}

/// Device posture for foldable hardware
enum FoldPosture {
  /// Standard flat screen (no active folding hinge)
  flat,

  /// Book posture (vertical hinge, split left/right)
  book,

  /// Tabletop posture (horizontal hinge, split top/bottom)
  tabletop,
}

class ResponsiveBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  static const double maxContentWidth = 520;
  static const double maxDualPaneWidth = 1200;
}

/// Information about the current screen dimensions, window size class, and foldable postures.
class ResponsiveContext {
  final Size size;
  final Orientation orientation;
  final WindowSizeClass sizeClass;
  final FoldPosture foldPosture;
  final Rect? hingeBounds;
  final EdgeInsets safeAreaPadding;

  const ResponsiveContext({
    required this.size,
    required this.orientation,
    required this.sizeClass,
    required this.foldPosture,
    this.hingeBounds,
    required this.safeAreaPadding,
  });

  bool get isCompact => sizeClass == WindowSizeClass.compact;
  bool get isMedium => sizeClass == WindowSizeClass.medium;
  bool get isExpanded => sizeClass == WindowSizeClass.expanded;
  bool get isFoldableSplit => foldPosture != FoldPosture.flat && hingeBounds != null;
  bool get isDualPane => isExpanded || isFoldableSplit || (isMedium && orientation == Orientation.landscape);
}

/// A builder widget that detects window size class and foldable physical display features (hinges/creases).
class FairGoResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveContext info) builder;

  const FairGoResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final orientation = mediaQuery.orientation;

    // Window size class determination
    final WindowSizeClass sizeClass;
    if (size.width < ResponsiveBreakpoints.compact) {
      sizeClass = WindowSizeClass.compact;
    } else if (size.width < ResponsiveBreakpoints.medium) {
      sizeClass = WindowSizeClass.medium;
    } else {
      sizeClass = WindowSizeClass.expanded;
    }

    // Foldable display feature detection (Hinge/Crease)
    FoldPosture posture = FoldPosture.flat;
    Rect? hingeRect;

    final displayFeatures = mediaQuery.displayFeatures;
    for (final feature in displayFeatures) {
      if (feature.type == ui.DisplayFeatureType.hinge || feature.type == ui.DisplayFeatureType.fold) {
        hingeRect = feature.bounds;
        if (feature.bounds.width < feature.bounds.height) {
          posture = FoldPosture.book;
        } else {
          posture = FoldPosture.tabletop;
        }
        break;
      }
    }

    final info = ResponsiveContext(
      size: size,
      orientation: orientation,
      sizeClass: sizeClass,
      foldPosture: posture,
      hingeBounds: hingeRect,
      safeAreaPadding: mediaQuery.padding,
    );

    return builder(context, info);
  }
}

/// Adaptive Dual-Pane layout that seamlessly splits primary and secondary views across
/// foldable hinges or large screens (Tablets/Desktops/Foldables).
class AdaptiveDualPane extends StatelessWidget {
  /// Primary pane (e.g. Map view, Search header)
  final Widget primary;

  /// Secondary pane (e.g. Booking sheet, Driver details, Payment options)
  final Widget secondary;

  /// Proportion of primary pane on expanded single screens (default: 0.55 = 55% primary, 45% secondary)
  final double primaryFlex;

  /// Optional gap between panes if not on a physical foldable hinge
  final double paneSpacing;

  /// Padding around the entire dual-pane structure
  final EdgeInsets padding;

  const AdaptiveDualPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 0.55,
    this.paneSpacing = 16.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FairGoResponsiveBuilder(
      builder: (context, info) {
        // 1. Compact phone screen -> Stack or single pane fallback
        if (info.isCompact && !info.isFoldableSplit) {
          return Stack(
            children: [
              Positioned.fill(child: primary),
              Align(
                alignment: Alignment.bottomCenter,
                child: secondary,
              ),
            ],
          );
        }

        // 2. Physical Foldable Hinge (Book posture) -> Split precisely along the physical hinge
        if (info.foldPosture == FoldPosture.book && info.hingeBounds != null) {
          final hinge = info.hingeBounds!;
          final screenWidth = info.size.width;
          final leftPaneWidth = hinge.left;
          final rightPaneWidth = screenWidth - hinge.right;

          return Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: leftPaneWidth, child: primary),
                SizedBox(width: hinge.width), // Avoid physical crease
                SizedBox(width: rightPaneWidth, child: secondary),
              ],
            ),
          );
        }

        // 3. Physical Foldable Hinge (Tabletop posture) -> Split top and bottom across horizontal crease
        if (info.foldPosture == FoldPosture.tabletop && info.hingeBounds != null) {
          final hinge = info.hingeBounds!;
          final screenHeight = info.size.height;
          final topPaneHeight = hinge.top;
          final bottomPaneHeight = screenHeight - hinge.bottom;

          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPaneHeight, child: primary),
                SizedBox(height: hinge.height), // Avoid horizontal crease
                SizedBox(height: bottomPaneHeight, child: secondary),
              ],
            ),
          );
        }

        // 4. Expanded / Tablet / Desktop landscape -> Adaptive flex split
        final primaryFlexInt = (primaryFlex * 100).round();
        final secondaryFlexInt = ((1.0 - primaryFlex) * 100).round();

        return Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: primaryFlexInt,
                child: primary,
              ),
              SizedBox(width: paneSpacing),
              Expanded(
                flex: secondaryFlexInt,
                child: secondary,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clamps text scale factor to ensure UI elements do not break on extreme accessibility text scalings.
class AccessibleTextScalerClamper extends StatelessWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const AccessibleTextScalerClamper({
    super.key,
    required this.child,
    this.minScale = 0.85,
    this.maxScale = 1.35,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: minScale,
      maxScaleFactor: maxScale,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: textScaler),
      child: child,
    );
  }
}
