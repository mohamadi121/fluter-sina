import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Screen size helper
enum ScreenSize {
  mobile,
  tablet,
  desktop,
}

/// Responsive helper class
class ResponsiveHelper {
  /// Get current screen size
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= Breakpoints.desktop) {
      return ScreenSize.desktop;
    } else if (width >= Breakpoints.tablet) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.mobile;
    }
  }

  /// Check if mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  /// Check if tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  /// Check if desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  /// Get responsive value
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  /// Get responsive columns for grid
  static int getColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveHelper.getScreenSize(context);
        return builder(context, screenSize);
      },
    );
  }
}

/// Responsive layout widget with mobile/tablet/desktop variants
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        switch (screenSize) {
          case ScreenSize.desktop:
            return desktop ?? tablet ?? mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Adaptive navigation scaffold that switches between bottom nav and rail
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final List<AdaptiveNavigationItem> destinations;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;
  final Widget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        if (screenSize == ScreenSize.mobile) {
          return Scaffold(
            appBar: appBar as PreferredSizeWidget?,
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
            floatingActionButton: floatingActionButton,
            drawer: drawer,
          );
        } else {
          return Scaffold(
            appBar: appBar as PreferredSizeWidget?,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: screenSize == ScreenSize.desktop
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.selected,
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
            drawer: drawer,
          );
        }
      },
    );
  }
}

/// Navigation item for adaptive scaffold
class AdaptiveNavigationItem {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const AdaptiveNavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        final columns = ResponsiveHelper.getColumns(context);
        
        return Padding(
          padding: padding,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 
                       padding.horizontal - 
                       (spacing * (columns - 1))) / columns,
                child: child,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
