import 'package:asoud/core/constants/constants.dart';
import 'package:asoud/core/router/app_routers.dart';
import 'package:asoud/core/config/env_config.dart';
import 'package:asoud/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asoud/features/business_card/presentation/bloc/business_bloc.dart';
import 'package:asoud/features/create_workspace/presentation/bloc/create_workspace_bloc.dart';
import 'package:asoud/features/job_managment/presentation/bloc/jobmanagment_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/add_product/add_product_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/bloc/market_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/comment/comment_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/theme/theme_bloc.dart';
import 'package:asoud/features/splash/blocs/splash_bloc.dart';
import 'package:asoud/features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import 'package:asoud/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:asoud/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:asoud/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment configuration in development
  if (EnvConfig.isDev) {
    debugPrint('🚀 Environment Configuration:');
    EnvConfig.summary.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }

  await locatorSetup();

  runApp(const asoud());
}

class asoud extends StatelessWidget {
  const asoud({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock to portrait orientation for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Use transparent for Material 3
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: 
            Theme.of(context).brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
        statusBarIconBrightness: 
            Theme.of(context).brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
      ),
      child: MultiBlocProvider(
        providers: [
          // Fire splash event once at creation time
          BlocProvider(create: (context) => locator<SplashBloc>()..add(SplashInitialEvent())),
          BlocProvider(create: (context) => locator<AuthBloc>()),
          BlocProvider(create: (context) => locator<CreateWorkSpaceBloc>()),
          BlocProvider(create: (context) => locator<JobmanagmentBloc>()),
          BlocProvider(create: (context) => locator<VendorBloc>()),
          BlocProvider(create: (context) => locator<WorkspaceBloc>()),
          BlocProvider(create: (context) => locator<AddProductBloc>()),
          BlocProvider(create: (context) => locator<ThemeBloc>()),
          BlocProvider(create: (context) => locator<CommentBloc>()),
          BlocProvider(create: (context) => locator<MarketBloc>()),
          BlocProvider(create: (context) => locator<BusinessBloc>()),
          BlocProvider(create: (context) => locator<SettingsBloc>()..add(const LoadSettingsEvent())),
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
          
          // Localization
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fa', ''), // Persian
            Locale('en', ''), // English
          ],
          locale: const Locale('fa', ''),
          
          title: 'آسود',
          
          // Apply improved Material 3 theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Respect system theme preference
        ),
      ),
    );
  }
}
