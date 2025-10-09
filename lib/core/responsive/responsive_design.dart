import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Advanced Responsive Design System
/// Handles different screen sizes with adaptive layouts and breakpoints
class ResponsiveDesign {
  ResponsiveDesign._();

  // Breakpoint definitions based on Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Minimum and maximum content widths
  static const double minContentWidth = 320;
  static const double maxContentWidth = 1200;

  /// Device type enumeration
  enum DeviceType {
    mobile,
    tablet,
    desktop,
    largeDesktop,
  }

  /// Screen orientation enumeration
  enum ScreenOrientation {
    portrait,
    landscape,
  }

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= largeDesktopBreakpoint) return DeviceType.largeDesktop;
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Get screen orientation
  static ScreenOrientation getOrientation(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height 
        ? ScreenOrientation.landscape 
        : ScreenOrientation.portrait;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == ScreenOrientation.landscape;
  }

  /// Get responsive value based on device type
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get number of columns for grid layouts
  static int getColumnsCount(BuildContext context, {
    int? forceColumns,
    double? itemWidth,
  }) {
    if (forceColumns != null) return forceColumns;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    if (itemWidth != null) {
      return math.max(1, (screenWidth / itemWidth).floor());
    }
    
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscape(context) ? 2 : 1;
      case DeviceType.tablet:
        return isLandscape(context) ? 3 : 2;
      case DeviceType.desktop:
        return 4;
      case DeviceType.largeDesktop:
        return 6;
    }
  }

  /// Get adaptive padding based on screen size
  static EdgeInsets getAdaptivePadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = responsiveValue(
      context: context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    
    return EdgeInsets.all(padding);
  }

  /// Get adaptive margin based on screen size
  static EdgeInsets getAdaptiveMargin(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final margin = responsiveValue(
      context: context,
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 24.0,
    );
    
    return EdgeInsets.all(margin);
  }

  /// Get content width with maximum constraint
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth;
      case DeviceType.tablet:
        return math.min(screenWidth * 0.9, 720);
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return math.min(screenWidth * 0.8, maxContentWidth);
    }
  }

  /// Get adaptive font size
  static double getAdaptiveFontSize(BuildContext context, {
    required double baseSize,
    double? scaleFactor,
  }) {
    final deviceType = getDeviceType(context);
    final factor = scaleFactor ?? 1.0;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize * factor;
      case DeviceType.tablet:
        return baseSize * factor * 1.1;
      case DeviceType.desktop:
        return baseSize * factor * 1.2;
      case DeviceType.largeDesktop:
        return baseSize * factor * 1.3;
    }
  }

  /// Get adaptive icon size
  static double getAdaptiveIconSize(BuildContext context, {
    double? baseSize,
  }) {
    final size = baseSize ?? 24.0;
    return responsiveValue(
      context: context,
      mobile: size,
      tablet: size * 1.2,
      desktop: size * 1.4,
    );
  }

  /// Get adaptive border radius
  static double getAdaptiveBorderRadius(BuildContext context, {
    double? baseRadius,
  }) {
    final radius = baseRadius ?? 16.0;
    return responsiveValue(
      context: context,
      mobile: radius,
      tablet: radius * 1.1,
      desktop: radius * 1.2,
    );
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get device pixel ratio
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Check if device has notch or dynamic island
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 24; // Standard status bar height
  }

  /// Get bottom safe area height (for home indicator)
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return getKeyboardHeight(context) > 0;
  }

  /// Get adaptive app bar height
  static double getAppBarHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }

  /// Get adaptive bottom navigation bar height
  static double getBottomNavHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: kBottomNavigationBarHeight,
      tablet: kBottomNavigationBarHeight + 8,
      desktop: kBottomNavigationBarHeight + 16,
    );
  }

  /// Get adaptive floating action button size
  static double getFABSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
    );
  }

  /// Get adaptive list tile height
  static double getListTileHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
    );
  }

  /// Get adaptive card elevation
  static double getCardElevation(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 2.0,
      tablet: 4.0,
      desktop: 6.0,
    );
  }

  /// Get adaptive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return responsiveValue(
      context: context,
      mobile: screenWidth * 0.9,
      tablet: math.min(screenWidth * 0.7, 480),
      desktop: math.min(screenWidth * 0.5, 560),
    );
  }

  /// Get layout constraints for different screen sizes
  static BoxConstraints getLayoutConstraints(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const BoxConstraints(
          maxWidth: mobileBreakpoint,
        );
      case DeviceType.tablet:
        return const BoxConstraints(
          minWidth: mobileBreakpoint,
          maxWidth: tabletBreakpoint,
        );
      case DeviceType.desktop:
        return const BoxConstraints(
          minWidth: tabletBreakpoint,
          maxWidth: desktopBreakpoint,
        );
      case DeviceType.largeDesktop:
        return const BoxConstraints(
          minWidth: desktopBreakpoint,
        );
    }
  }
}

/// Responsive Builder Widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDesign.responsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// Responsive Grid Widget
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.columnsCount,
    this.itemAspectRatio = 1.0,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columnsCount;
  final double itemAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = columnsCount ?? ResponsiveDesign.getColumnsCount(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final itemHeight = itemWidth / itemAspectRatio;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Responsive Container Widget
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.centerContent = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final contentWidth = maxWidth ?? ResponsiveDesign.getContentWidth(context);
    final adaptivePadding = padding ?? ResponsiveDesign.getAdaptivePadding(context);
    final adaptiveMargin = margin ?? ResponsiveDesign.getAdaptiveMargin(context);
    
    Widget content = Container(
      width: contentWidth,
      padding: adaptivePadding,
      margin: adaptiveMargin,
      child: child,
    );
    
    if (centerContent && ResponsiveDesign.isDesktop(context)) {
      content = Center(child: content);
    }
    
    return content;
  }
}