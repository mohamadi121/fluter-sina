import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asood/core/di/service_locator.dart';
import 'package:asood/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asood/features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import 'package:asood/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:asood/features/market/presentation/blocs/bloc/market_bloc.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';
import 'package:asood/features/market/presentation/blocs/theme/theme_bloc.dart';
import 'package:asood/features/splash/blocs/splash_bloc.dart';

/// Centralized BLoC scope management to prevent memory leaks
/// 
/// This widget provides a way to create BLoCs with proper scoping
/// and automatic disposal when the widget is removed from the tree.
/// 
/// Usage:
/// ```dart
/// BlocScope<AuthBloc>(
///   create: () => ServiceLocator.get<AuthBloc>(),
///   child: LoginScreen(),
/// )
/// ```
class BlocScope<T extends BlocBase<Object?>> extends StatelessWidget {
  final T Function() create;
  final Widget child;
  final bool lazy;

  const BlocScope({
    super.key,
    required this.create,
    required this.child,
    this.lazy = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<T>(
      create: (_) => create(),
      lazy: lazy,
      child: child,
    );
  }
}

/// Multiple BLoC scope for providing multiple BLoCs with proper disposal
class MultiBlocScope extends StatelessWidget {
  final List<BlocProvider> providers;
  final Widget child;

  const MultiBlocScope({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: providers,
      child: child,
    );
  }

  /// Factory method to create providers with automatic disposal
  static List<BlocProvider> createProviders({
    required List<BlocProvider Function()> factories,
  }) {
    return factories.map((factory) => factory()).toList();
  }
}

/// Page-level BLoC provider for screens that need specific BLoCs
/// 
/// This should be used instead of global BLoC providers for
/// screens that don't need to share state across the entire app.
class PageBlocProvider<T extends BlocBase<Object?>> extends StatefulWidget {
  final T Function() create;
  final Widget Function(BuildContext context, T bloc) builder;

  const PageBlocProvider({
    super.key,
    required this.create,
    required this.builder,
  });

  @override
  State<PageBlocProvider<T>> createState() => _PageBlocProviderState<T>();
}

class _PageBlocProviderState<T extends BlocBase<Object?>>
    extends State<PageBlocProvider<T>> {
  late final T _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.create();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<T>.value(
      value: _bloc,
      child: widget.builder(context, _bloc),
    );
  }
}

/// Conditional BLoC provider that only creates BLoC when condition is met
class ConditionalBlocProvider<T extends BlocBase<Object?>> extends StatelessWidget {
  final bool condition;
  final T Function() create;
  final Widget child;
  final Widget? fallback;

  const ConditionalBlocProvider({
    super.key,
    required this.condition,
    required this.create,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return BlocProvider<T>(
        create: (_) => create(),
        child: child,
      );
    }
    return fallback ?? child;
  }
}

/// Helper extension for easy BLoC scoping
extension BlocScopeExtension on Widget {
  /// Wrap widget with a BLoC scope
  Widget withBloc<T extends BlocBase<Object?>>(T Function() create) {
    return BlocScope<T>(
      create: create,
      child: this,
    );
  }

  /// Wrap widget with multiple BLoC scopes
  Widget withBlocs(List<BlocProvider> providers) {
    return MultiBlocScope(
      providers: providers,
      child: this,
    );
  }
}

/// BLoC factory helpers for common patterns
class BlocFactories {
  BlocFactories._();

  /// Create auth-related BLoCs
  static List<BlocProvider> auth() => [
    BlocProvider<AuthBloc>(
      create: (_) => ServiceLocator.get<AuthBloc>(),
    ),
  ];

  /// Create vendor-related BLoCs
  static List<BlocProvider> vendor() => [
    BlocProvider<VendorBloc>(
      create: (_) => ServiceLocator.get<VendorBloc>(),
    ),
    BlocProvider<WorkspaceBloc>(
      create: (_) => ServiceLocator.get<WorkspaceBloc>(),
    ),
  ];

  /// Create market-related BLoCs
  static List<BlocProvider> market() => [
    BlocProvider<MarketBloc>(
      create: (_) => ServiceLocator.get<MarketBloc>(),
    ),
    BlocProvider<AddProductBloc>(
      create: (_) => ServiceLocator.get<AddProductBloc>(),
    ),
    BlocProvider<ThemeBloc>(
      create: (_) => ServiceLocator.get<ThemeBloc>(),
    ),
  ];

  /// Create essential app-level BLoCs (these can remain global)
  static List<BlocProvider> essential() => [
    BlocProvider<SplashBloc>(
      create: (_) => ServiceLocator.get<SplashBloc>(),
    ),
    BlocProvider<AuthBloc>(
      create: (_) => ServiceLocator.get<AuthBloc>(),
    ),
  ];
}