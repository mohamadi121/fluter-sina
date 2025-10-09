import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../di/service_locator.dart';
import '../constants/app_routes.dart';
import 'route_guards.dart';
import 'route_transitions.dart';
import 'smart_home_shell.dart';
import 'error_pages.dart';

// Auth imports
import '../../features/auth/presentation/screens/enhanced_login_screen.dart';
import '../../features/auth/presentation/screens/enhanced_otp_screen.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';

// Dashboard imports  
import '../../features/splash/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/smart_home_dashboard_screen.dart';
import '../../features/devices/presentation/screens/device_management_screen.dart';
import '../../features/dashboard/presentation/screens/environmental_control_screen.dart';
import '../../features/dashboard/presentation/screens/performance_dashboard_screen.dart';

// Profile and Settings (placeholders)
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

// Testing
import '../testing/api_configuration_test_screen.dart';

// Services
import '../../features/auth/services/security_service.dart';

/// Modern GoRouter Configuration for Smart Home App
class AppRouter {
  static final SecurityService _security = SecurityService();
  
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: _handleRedirection,
    routes: [
      // Splash Route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => ServiceLocator.get<AuthBloc>(),
            child: const EnhancedLoginScreen(),
          ),
          transitionsBuilder: AppRouteTransitions.slideFromBottom,
        ),
      ),

      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => ServiceLocator.get<AuthBloc>(),
            child: EnhancedOtpScreen(
              phoneNumber: state.extra as String? ?? '',
            ),
          ),
          transitionsBuilder: AppRouteTransitions.slideFromRight,
        ),
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => SmartHomeShell(child: child),
        routes: [
          // Dashboard Routes
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SmartHomeDashboardScreen(),
              transitionsBuilder: AppRouteTransitions.fadeIn,
            ),
            routes: [
              // Device Management
              GoRoute(
                path: '/devices',
                name: 'device-management',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const DeviceManagementScreen(),
                  transitionsBuilder: AppRouteTransitions.slideFromRight,
                ),
              ),

              // Environmental Controls
              GoRoute(
                path: '/environment',
                name: 'environmental-control',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const EnvironmentalControlScreen(),
                  transitionsBuilder: AppRouteTransitions.slideFromRight,
                ),
              ),

              // Performance Dashboard
              GoRoute(
                path: '/performance',
                name: 'performance-dashboard',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const PerformanceDashboardScreen(),
                  transitionsBuilder: AppRouteTransitions.slideFromRight,
                ),
              ),

              // API Configuration Test
              GoRoute(
                path: '/api-test',
                name: 'api-configuration-test',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ApiConfigurationTestScreen(),
                  transitionsBuilder: AppRouteTransitions.slideFromRight,
                ),
              ),
            ],
          ),

          // Profile Routes
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: AppRouteTransitions.slideFromRight,
            ),
          ),

          // Settings Routes
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: AppRouteTransitions.slideFromRight,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => SmartHomeErrorPage(
      error: state.error,
      routeName: state.matchedLocation,
    ),
  );

  /// Handle global redirection logic
  static String? _handleRedirection(BuildContext context, GoRouterState state) {
    final isAuthenticated = _security.isAuthenticated;
    final currentLocation = state.matchedLocation;

    // Skip redirect for splash screen
    if (currentLocation == AppRoutes.splash) {
      return null;
    }

    // Redirect to login if not authenticated
    if (!isAuthenticated && !_isAuthRoute(currentLocation)) {
      return AppRoutes.login;
    }

    // Redirect to dashboard if authenticated and on auth routes
    if (isAuthenticated && _isAuthRoute(currentLocation)) {
      return AppRoutes.dashboard;
    }

    return null;
  }

  /// Check if route is authentication related
  static bool _isAuthRoute(String route) {
    return route == AppRoutes.login || route == AppRoutes.otp;
  }
}
      GoRoute(
        path: AppRoutes.vendorHome,
        builder: (context, state) {
          // final title = state.extra as String;
          return VendorHomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.createWorkSpace,
        builder: (context, state) => CreateWorkSpaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobManagement,
        builder: (context, state) {
          context.read<JobmanagmentBloc>().add(ResetJobManagmentBloc());
          context.read<JobmanagmentBloc>().add(LoadCategory());
          return JobManagementScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.storeDetail,
        builder: (context, state) {
          final market = state.extra as MarketModel;
          return StoreDetailScreen(market: market);
        },
      ),
      GoRoute(
        path: AppRoutes.marketPreview,
        builder: (context, state) {
          final market = state.extra as MarketModel;
          return MarketPreviewScreen(market: market);
        },
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (context, state) => ChatList(),
      ),
      GoRoute(
        path: AppRoutes.storeInfo,
        builder: (context, state) => StoreInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.inquiryRequests,
        builder: (context, state) => InquiryRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.shoppingCart,
        builder: (context, state) => const ShoppingCartPage(),
      ),
      GoRoute(
        path: AppRoutes.mainInquiry,
        builder: (context, state) => const MainInquiry(),
      ),
      GoRoute(
        path: AppRoutes.createProduct,
        builder: (context, state) {
          print("---------------");
          print(state.extra);
          print(state.extra.runtimeType);
          List extra = state.extra as List;
          final marketId = extra[0];
          final themeId = extra[1];
          final themeIndex = extra[2];
          return CreateProduct(
            marketId: marketId,
            themeId: themeId,
            themeIndex: themeIndex,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.product,
        builder: (context, state) {
          List extra = state.extra as List;

          return ProductScreen(productDetails: extra[0]);
        },
      ),
      GoRoute(
        path: AppRoutes.markets,
        builder: (context, state) => MarketsScreen(),
      ),
      // GoRoute(
      //   path: AppRoutes.createBusinessCard,
      //   builder: (context, state) => CreateBusinessCard(isEdit: false),
      // ),
      GoRoute(
        path: AppRoutes.business,
        builder: (context, state) => BusinessPart(),
      ),
      GoRoute(path: AppRoutes.finance, builder: (context, state) => Finance()),
      GoRoute(
        path: AppRoutes.bankCardList,
        builder: (context, state) => BankCardListScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerDashboard,
        builder: (context, state) => CustomerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorDashboard,
        builder: (context, state) => VendorHomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.panelConfig,
        builder: (context, state) => PanelConfigScreen(),
      ),
      GoRoute(
        path: AppRoutes.panelInbox,
        builder: (context, state) => PanelInboxScreen(),
      ),

      GoRoute(
        path: AppRoutes.takhfif,
        builder: (context, state) => TakhfifScreen(),
      ),
      GoRoute(
        path: AppRoutes.fontColorSettings,
        builder: (context, state) => FontColorSettingScreen(),
      ),
      GoRoute(
        path: AppRoutes.colorSettings,
        builder: (context, state) => ColorSettingScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => MyBookmarks(),
      ),
    ],
  );
}
