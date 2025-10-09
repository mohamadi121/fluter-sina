/// Smart Home App Route Constants
class AppRoutes {
  AppRoutes._();

  // Core routes
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String deviceManagement = '/dashboard/devices';
  static const String environmentalControl = '/dashboard/environment';
  static const String performanceDashboard = '/dashboard/performance';
  static const String apiConfigurationTest = '/dashboard/api-test';

  // User routes
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Device specific routes
  static const String deviceDetail = '/device/:deviceId';
  static const String deviceControl = '/device/:deviceId/control';
  static const String deviceHistory = '/device/:deviceId/history';

  // Smart features routes
  static const String automation = '/automation';
  static const String scenes = '/scenes';
  static const String schedules = '/schedules';
  static const String security = '/security';

  // Analytics routes
  static const String analytics = '/analytics';
  static const String energyUsage = '/analytics/energy';
  static const String performanceStats = '/analytics/performance';

  // System routes
  static const String systemHealth = '/system/health';
  static const String networkStatus = '/system/network';
  static const String deviceStatus = '/system/devices';

  /// Generate device detail route
  static String deviceDetailRoute(String deviceId) =>
      '/device/$deviceId';

  /// Generate device control route
  static String deviceControlRoute(String deviceId) =>
      '/device/$deviceId/control';

  /// Generate device history route
  static String deviceHistoryRoute(String deviceId) =>
      '/device/$deviceId/history';

  /// Get route name from path
  static String getRouteName(String path) {
    switch (path) {
      case splash:
        return 'Splash';
      case login:
        return 'Login';
      case otp:
        return 'OTP Verification';
      case dashboard:
        return 'Smart Home Dashboard';
      case deviceManagement:
        return 'Device Management';
      case environmentalControl:
        return 'Environmental Control';
      case performanceDashboard:
        return 'Performance Dashboard';
      case profile:
        return 'Profile';
      case settings:
        return 'Settings';
      case automation:
        return 'Automation';
      case scenes:
        return 'Scenes';
      case schedules:
        return 'Schedules';
      case security:
        return 'Security';
      case analytics:
        return 'Analytics';
      case energyUsage:
        return 'Energy Usage';
      case performanceStats:
        return 'Performance Statistics';
      case systemHealth:
        return 'System Health';
      case networkStatus:
        return 'Network Status';
      case deviceStatus:
        return 'Device Status';
      default:
        if (path.startsWith('/device/')) {
          return 'Device Details';
        }
        return 'Unknown';
    }
  }

  /// Check if route requires authentication
  static bool requiresAuth(String path) {
    const publicRoutes = [splash, login, otp];
    return !publicRoutes.contains(path);
  }

  /// Check if route is a dashboard route
  static bool isDashboardRoute(String path) {
    return path.startsWith('/dashboard');
  }

  /// Check if route is a system route
  static bool isSystemRoute(String path) {
    return path.startsWith('/system');
  }

  /// Check if route is a device route
  static bool isDeviceRoute(String path) {
    return path.startsWith('/device');
  }

  /// Get main navigation routes
  static List<String> get mainNavigationRoutes => [
    dashboard,
    deviceManagement,
    environmentalControl,
    performanceDashboard,
    profile,
    settings,
  ];

  /// Get quick access routes
  static List<String> get quickAccessRoutes => [
    automation,
    scenes,
    schedules,
    security,
  ];

  /// Get analytics routes
  static List<String> get analyticsRoutes => [
    analytics,
    energyUsage,
    performanceStats,
  ];

  /// Get system monitoring routes
  static List<String> get systemRoutes => [
    systemHealth,
    networkStatus,
    deviceStatus,
  ];
}