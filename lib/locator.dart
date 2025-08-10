import 'package:asoud/core/constants/endpoints.dart';
import 'package:asoud/core/http_client/api_client.dart';
import 'package:get_it/get_it.dart';

// Auth
import 'package:asoud/features/auth/data/data_source/auth_api_service.dart';
import 'package:asoud/features/auth/data/repository/auth_repository_imp.dart';
import 'package:asoud/features/auth/domain/repository/auth_repository.dart';
import 'package:asoud/features/auth/presentation/blocs/auth_bloc.dart';

// Category/Job Management
import 'package:asoud/features/job_managment/data/data_source/category_api_service.dart';
import 'package:asoud/features/job_managment/data/repository/category_repository_imp.dart';
import 'package:asoud/features/job_managment/domain/repository/category_repository.dart';
import 'package:asoud/features/job_managment/presentation/bloc/jobmanagment_bloc.dart';

// Market/Product
import 'package:asoud/features/market/data/data_source/product_api_service.dart';
import 'package:asoud/features/market/data/repository/product_repository_imp.dart';
import 'package:asoud/features/market/domain/repository/product_repository.dart';
import 'package:asoud/features/market/presentation/blocs/add_product/add_product_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/bloc/market_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/comment/comment_bloc.dart';
import 'package:asoud/features/market/presentation/blocs/theme/theme_bloc.dart';

// Create Workspace
import 'package:asoud/features/create_workspace/data/data_source/market_api_service.dart';
import 'package:asoud/features/create_workspace/data/data_source/region_api_services.dart';
import 'package:asoud/features/create_workspace/data/repository/create_market_repository_imp.dart';
import 'package:asoud/features/create_workspace/data/repository/region_repository_imp.dart';
import 'package:asoud/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:asoud/features/create_workspace/domain/repository/region_repository.dart';
import 'package:asoud/features/create_workspace/presentation/bloc/create_workspace_bloc.dart';

// Other Features
import 'package:asoud/features/splash/blocs/splash_bloc.dart';
import 'package:asoud/features/business_card/presentation/bloc/business_bloc.dart';
import 'package:asoud/features/customer/presentation/blocs/customer/customer_bloc.dart';
import 'package:asoud/features/customer/presentation/blocs/profile/profile_bloc.dart';
import 'package:asoud/features/product/blocs/product_bloc.dart';
import 'package:asoud/features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import 'package:asoud/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:asoud/features/settings/data/settings_repository.dart';
import 'package:asoud/features/settings/presentation/bloc/settings_bloc.dart';

GetIt locator = GetIt.instance;

locatorSetup() async {
  /// Dio client
  locator.registerLazySingleton<DioClient>(
    () => DioClient(appBaseUrl: Endpoints.baseUrl),
  );

  /// API Services
  locator.registerLazySingleton<AuthApiService>(
    () => AuthApiService(dioClient: locator<DioClient>()),
  );
  locator.registerLazySingleton<CategoryApiService>(
    () => CategoryApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => CreateMarketApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => RegionApiServices(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => ProductApiService(dioClient: locator<DioClient>()),
  );

  /// Repositories
  locator.registerLazySingleton<AuthRepositoryImp>(
    () => AuthRepositoryImp(locator<AuthApiService>()),
  );
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImp(locator<CategoryApiService>()),
  );
  locator.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImp(locator<ProductApiService>()),
  );
  locator.registerLazySingleton<CreateMarketRepository>(
    () => CreateMarketRepositoryImp(locator<CreateMarketApiService>()),
  );
  locator.registerLazySingleton<RegionRepository>(
    () => RegionRepositoryImp(locator<RegionApiServices>()),
  );

  /// BLOCs
  locator.registerFactory(() => SplashBloc());
  locator.registerFactory(
    () => AuthBloc(authRepository: locator<AuthRepositoryImp>()),
  );
  locator.registerFactory(
    () => CreateWorkSpaceBloc(
      locator<CreateMarketRepository>(),
      locator<RegionRepository>(),
    ),
  );
  locator.registerFactory(
    () => JobmanagmentBloc(locator<CategoryRepository>()),
  );
  locator.registerFactory(
    () => VendorBloc(),
  );
  locator.registerFactory(
    () => WorkspaceBloc(locator<CreateMarketRepository>()),
  );
  locator.registerFactory(() => AddProductBloc(locator<ProductRepository>()));
  locator.registerFactory(() => ThemeBloc());
  locator.registerFactory(() => CommentBloc());
  locator.registerFactory(
    () => MarketBloc(productRepository: locator<ProductRepository>()),
  );
  locator.registerFactory(() => BusinessBloc());
  locator.registerFactory(() => ProfileBloc());
  locator.registerFactory(() => CustomerBloc());
  locator.registerFactory(() => ProductBloc());
  locator.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
  locator.registerFactory<SettingsBloc>(() => SettingsBloc(locator<SettingsRepository>()));
}
