import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Core imports
import '../constants/endpoints.dart';
import '../http_client/api_client.dart';
import '../firebase/firebase_manager.dart';
import '../performance/performance_monitor.dart';
import '../performance/battery_optimizer.dart';
import '../performance/firebase_performance_service.dart';
import '../network/websocket_service.dart';
import '../network/enhanced_http_client.dart';
import '../offline/offline_manager.dart';

// Auth imports
import '../../features/auth/data/data_source/auth_api_service.dart';
import '../../features/auth/data/repository/auth_repository_imp.dart';
import '../../features/auth/domain/repository/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/services/security_service.dart';
import '../../features/auth/services/biometric_auth_service.dart';
import '../../features/auth/services/apple_signin_service.dart';

// Other feature imports (keeping existing ones)
import '../../features/create_workspace/domain/usecases/create_market_usecases.dart';
import '../../features/job_managment/domain/usecases/category_usecases.dart';
import '../../features/market/domain/usecases/product_usecases.dart';
import '../../features/create_workspace/data/data_source/market_api_service.dart';
import '../../features/create_workspace/data/data_source/region_api_services.dart';
import '../../features/create_workspace/data/repository/create_market_repository_imp.dart';
import '../../features/create_workspace/data/repository/region_repository_imp.dart';
import '../../features/create_workspace/domain/repository/create_market_repository.dart';
import '../../features/create_workspace/domain/repository/region_repository.dart';
import '../../features/create_workspace/presentation/bloc/create_workspace_bloc.dart';
import '../../features/job_managment/data/data_source/category_api_service.dart';
import '../../features/job_managment/data/repository/category_repository_imp.dart';
import '../../features/job_managment/domain/repository/category_repository.dart';
import '../../features/job_managment/presentation/bloc/jobmanagment_bloc.dart';
import '../../features/market/data/data_source/product_api_service.dart';
import '../../features/market/data/repository/product_repository_imp.dart';
import '../../features/market/domain/repository/product_repository.dart';
import '../../features/market/presentation/blocs/add_product/add_product_bloc.dart';
import '../../features/market/presentation/blocs/bloc/market_bloc.dart';
import '../../features/market/presentation/blocs/comment/comment_bloc.dart';
import '../../features/market/presentation/blocs/theme/theme_bloc.dart';
import '../../features/product/blocs/product_bloc.dart';
import '../../features/splash/blocs/splash_bloc.dart';
import '../../features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import '../../features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import '../../features/business_card/presentation/bloc/business_bloc.dart';
import '../../features/customer/presentation/blocs/customer/customer_bloc.dart';
import '../../features/customer/presentation/blocs/profile/profile_bloc.dart';

class ServiceLocator {
  static final GetIt _instance = GetIt.instance;

  static T get<T extends Object>() => _instance<T>();

  static bool get isRegistered => _instance.isRegistered;

  static Future<void> initializeDependencies() async {
    await _registerCore();
    await _registerCoreServices();
    await _registerAuthServices();
    await _registerDataSources();
    await _registerRepositories();
    await _registerUseCases();
    _registerBlocFactories();
  }

  static Future<void> _registerCore() async {
    _instance.registerLazySingleton<DioClient>(
      () => DioClient(appBaseUrl: Endpoints.baseUrl),
    );
  }

  static Future<void> _registerCoreServices() async {
    // Enhanced HTTP Client
    _instance.registerLazySingleton<EnhancedHttpClient>(
      () => EnhancedHttpClient(baseUrl: Endpoints.baseUrl),
    );

    // Firebase services
    _instance.registerLazySingleton<FirebaseManager>(
      () => FirebaseManager(),
    );
    
    // Performance services
    _instance.registerLazySingleton<PerformanceMonitor>(
      () => PerformanceMonitor(),
    );
    
    _instance.registerLazySingleton<BatteryOptimizer>(
      () => BatteryOptimizer(),
    );
    
    _instance.registerLazySingleton<FirebasePerformanceService>(
      () => FirebasePerformanceService(),
    );

    // Network services
    _instance.registerLazySingleton<WebSocketService>(
      () => WebSocketService(),
    );

    // Offline manager
    _instance.registerLazySingleton<OfflineManager>(
      () => OfflineManager(),
    );
  }

  static Future<void> _registerAuthServices() async {
    // Security services
    _instance.registerLazySingleton<SecurityService>(
      () => SecurityService(),
    );
    
    _instance.registerLazySingleton<BiometricAuthService>(
      () => BiometricAuthService(),
    );
    
    _instance.registerLazySingleton<AppleSignInService>(
      () => AppleSignInService(),
    );
  }

  static Future<void> _registerDataSources() async {
    _instance.registerFactory<AuthApiService>(
      () => AuthApiService(dioClient: get<DioClient>()),
    );

    _instance.registerFactory<CategoryApiService>(
      () => CategoryApiService(dioClient: get<DioClient>()),
    );

    _instance.registerFactory<CreateMarketApiService>(
      () => CreateMarketApiService(dioClient: get<DioClient>()),
    );

    _instance.registerFactory<RegionApiServices>(
      () => RegionApiServices(dioClient: get<DioClient>()),
    );

    _instance.registerFactory<ProductApiService>(
      () => ProductApiService(dioClient: get<DioClient>()),
    );
  }

  static Future<void> _registerRepositories() async {
    _instance.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImp(get<AuthApiService>()),
    );

    _instance.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImp(get<CategoryApiService>()),
    );

    _instance.registerLazySingleton<CreateMarketRepository>(
      () => CreateMarketRepositoryImp(get<CreateMarketApiService>()),
    );

    _instance.registerLazySingleton<RegionRepository>(
      () => RegionRepositoryImp(get<RegionApiServices>()),
    );

    _instance.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImp(get<ProductApiService>()),
    );
  }

  static Future<void> _registerUseCases() async {
    // Auth UseCases
    _instance.registerLazySingleton<SendOtpUseCase>(
      () => SendOtpUseCase(get<AuthRepository>()),
    );

    _instance.registerLazySingleton<VerifyOtpUseCase>(
      () => VerifyOtpUseCase(get<AuthRepository>()),
    );

    _instance.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(get<AuthRepository>()),
    );

    // Create Market UseCases
    _instance.registerLazySingleton<CreateMarketUseCase>(
      () => CreateMarketUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<GetMarketListUseCase>(
      () => GetMarketListUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<CreateMarketContactUseCase>(
      () => CreateMarketContactUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<CreateMarketLocationUseCase>(
      () => CreateMarketLocationUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<CreateMarketScheduleUseCase>(
      () => CreateMarketScheduleUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<UploadMarketLogoUseCase>(
      () => UploadMarketLogoUseCase(get<CreateMarketRepository>()),
    );

    _instance.registerLazySingleton<SetMarketThemeUseCase>(
      () => SetMarketThemeUseCase(get<CreateMarketRepository>()),
    );

    // Category UseCases
    _instance.registerLazySingleton<GetCategoryListUseCase>(
      () => GetCategoryListUseCase(get<CategoryRepository>()),
    );

    _instance.registerLazySingleton<GetMainSubCategoryListUseCase>(
      () => GetMainSubCategoryListUseCase(get<CategoryRepository>()),
    );

    _instance.registerLazySingleton<GetSubCategoryListUseCase>(
      () => GetSubCategoryListUseCase(get<CategoryRepository>()),
    );

    // Product UseCases
    _instance.registerLazySingleton<GetProductListUseCase>(
      () => GetProductListUseCase(get<ProductRepository>()),
    );

    _instance.registerLazySingleton<CreateProductUseCase>(
      () => CreateProductUseCase(get<ProductRepository>()),
    );

    _instance.registerLazySingleton<CreateProductDiscountUseCase>(
      () => CreateProductDiscountUseCase(get<ProductRepository>()),
    );

    _instance.registerLazySingleton<CreateMarketThemeUseCase>(
      () => CreateMarketThemeUseCase(get<ProductRepository>()),
    );

    _instance.registerLazySingleton<GetMarketThemeUseCase>(
      () => GetMarketThemeUseCase(get<ProductRepository>()),
    );

    _instance.registerLazySingleton<UpdateMarketThemeUseCase>(
      () => UpdateMarketThemeUseCase(get<ProductRepository>()),
    );
  }

  static void _registerBlocFactories() {
    _instance.registerFactory<SplashBloc>(() => SplashBloc());

    _instance.registerFactory<AuthBloc>(
      () => AuthBloc(
        sendOtpUseCase: get<SendOtpUseCase>(),
        verifyOtpUseCase: get<VerifyOtpUseCase>(),
        logoutUseCase: get<LogoutUseCase>(),
      ),
    );

    _instance.registerFactory<CreateWorkSpaceBloc>(
      () => CreateWorkSpaceBloc(
        get<CreateMarketRepository>(),
        get<RegionRepository>(),
      ),
    );

    _instance.registerFactory<JobmanagmentBloc>(
      () => JobmanagmentBloc(
        getCategoryListUseCase: get<GetCategoryListUseCase>(),
        getMainSubCategoryListUseCase: get<GetMainSubCategoryListUseCase>(),
        getSubCategoryListUseCase: get<GetSubCategoryListUseCase>(),
      ),
    );

    _instance.registerFactory<VendorBloc>(
      () => VendorBloc(get<CreateMarketRepository>()),
    );

    _instance.registerFactory<WorkspaceBloc>(
      () => WorkspaceBloc(get<CreateMarketRepository>()),
    );

    _instance.registerFactory<AddProductBloc>(
      () => AddProductBloc(get<ProductRepository>()),
    );

    _instance.registerFactory<ThemeBloc>(() => ThemeBloc());

    _instance.registerFactory<CommentBloc>(() => CommentBloc());

    _instance.registerFactory<MarketBloc>(
      () => MarketBloc(productRepository: get<ProductRepository>()),
    );

    _instance.registerFactory<BusinessBloc>(() => BusinessBloc());

    _instance.registerFactory<ProfileBloc>(() => ProfileBloc());

    _instance.registerFactory<CustomerBloc>(() => CustomerBloc());

    _instance.registerFactory<ProductBloc>(() => ProductBloc());
  }

  static Future<void> reset() async {
    await _instance.reset();
  }

  static void unregister<T extends Object>() {
    if (_instance.isRegistered<T>()) {
      _instance.unregister<T>();
    }
  }
}