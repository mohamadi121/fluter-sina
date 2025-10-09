import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Core imports
import 'core/constants/constants.dart';
import 'core/router/app_routers.dart';
import 'core/di/service_locator.dart';
import 'core/firebase/firebase_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/performance/performance_monitor.dart';
import 'core/performance/battery_optimizer.dart';
import 'core/performance/firebase_performance_service.dart';
import 'core/network/websocket_service.dart';
import 'core/network/enhanced_http_client.dart';
import 'core/offline/offline_manager.dart';

// Auth imports
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/services/security_service.dart';
import 'features/auth/services/biometric_auth_service.dart';
import 'features/auth/services/apple_signin_service.dart';

// Other feature imports
import 'features/splash/blocs/splash_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await FirebaseManager().initialize();
  
  // Initialize core services
  await SecurityService().initialize();
  await PerformanceMonitor().initialize();
  await BatteryOptimizer().initialize();
  await FirebasePerformanceService().initialize();
  
  // Initialize service locator
  await ServiceLocator.initializeDependencies();

  // Initialize network services after service locator
  await WebSocketService().initialize();
  await OfflineManager().initialize();

  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock device orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppTheme.primaryColor,
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: AppTheme.primaryColor,
        systemNavigationBarDividerColor: AppTheme.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
      child: MultiBlocProvider(
        providers: [
          // Core app-level BLoCs
          BlocProvider(create: (context) => ServiceLocator.get<SplashBloc>()),
          BlocProvider(create: (context) => ServiceLocator.get<AuthBloc>()),
        ],
        child: MaterialApp.router(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child as Widget,
            );
          },
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('fa', ''),
          ],
          locale: const Locale('fa', ''),
          title: 'Smart Home',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
        ),
      ),
    );
  }
}
