import 'package:asood/features/customer/data/public_market_api_service.dart';
import 'package:asood/features/job_managment/data/data_source/category_api_service.dart';
import 'package:asood/features/create_workspace/data/data_source/market_api_service.dart';
import 'package:asood/features/create_workspace/data/data_source/region_api_services.dart';
import 'package:asood/features/job_managment/data/repository/category_repository_imp.dart';
import 'package:asood/features/create_workspace/data/repository/create_market_repository_imp.dart';
import 'package:asood/features/create_workspace/data/repository/region_repository_imp.dart';

import 'package:asood/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:asood/features/create_workspace/domain/repository/region_repository.dart';
import 'package:asood/features/create_workspace/presentation/bloc/create_workspace_bloc.dart';
import 'package:asood/features/job_managment/domain/repository/category_repository.dart';
import 'package:asood/features/job_managment/presentation/bloc/jobmanagment_bloc.dart';
import 'package:asood/features/market/data/data_source/product_api_service.dart';
import 'package:asood/features/market/data/repository/product_repository_imp.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';
import 'package:asood/features/market/presentation/blocs/bloc/market_bloc.dart';
import 'package:asood/features/market/presentation/blocs/theme/theme_bloc.dart';
import 'package:asood/features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import 'package:asood/features/vendor/presentation/bloc/workspace/workspace_bloc.dart';
import 'package:asood/features/cart/data/data_source/cart_api_service.dart';
import 'package:asood/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:asood/features/wallet/data/data_source/wallet_api_service.dart';
import 'package:asood/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:asood/features/payment/data/data_source/payment_api_service.dart';
import 'package:asood/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/auth/token_storage.dart';
import 'package:asood/core/auth/websocket_ticket_api.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/features/auth/data/data_source/auth_api_service.dart';
import 'package:asood/features/bookmarks/bloc/bookmark_cubit.dart';
import 'package:asood/features/bookmarks/data/bookmark_api_service.dart';
import 'package:asood/features/chat/blocs/chat_list_cubit.dart';
import 'package:asood/features/chat/data/chat_api_service.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/chat_socket.dart';
import 'package:asood/features/chat/data/support_api_service.dart';
import 'package:asood/features/inquiry/data/data_source/inquiry_api_service.dart';
import 'package:asood/features/inquiry/data/repository/inquiry_repository_imp.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';
import 'package:asood/features/inquiry/presentation/blocs/inquiry_bloc.dart';
import 'package:asood/features/inquiry/presentation/blocs/inquiry_list_cubit.dart';
import 'package:asood/features/notification/blocs/notification_bloc.dart';
import 'package:asood/features/notification/data/notification_api_service.dart';
import 'package:asood/features/cart/data/data_source/owner_order_api_service.dart';
import 'package:asood/features/reservation/blocs/reservation_bloc.dart';
import 'package:asood/features/reservation/data/reservation_api_service.dart';
import 'package:asood/features/analytics/data/analytics_api_service.dart';
import 'package:asood/features/affiliate/data/affiliate_api_service.dart';
import 'package:asood/features/referral/data/referral_api_service.dart';
import 'package:asood/features/profile/data/profile_api_service.dart';
import 'package:asood/features/bank_card/data/bank_api_service.dart';
import 'package:asood/features/bank_card/bloc/bank_info_cubit.dart';
import 'package:asood/features/auth/data/repository/auth_repository_imp.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';
import 'package:asood/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:asood/features/splash/blocs/splash_bloc.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/data/discount_api_service.dart';

GetIt locator = GetIt.instance;

locatorSetup() async {
  /// Auth session (single owner of the token)
  locator.registerLazySingleton<TokenStorage>(() => const SecureTokenStorage());
  locator.registerLazySingleton<AuthSession>(
    () => AuthSession(locator<TokenStorage>()),
  );

  /// Dio client
  locator.registerLazySingleton<DioClient>(
    () => DioClient(
      appBaseUrl: Endpoints.baseUrl,
      authSession: locator<AuthSession>(),
    ),
  );
  locator.registerFactory(
    () => WebSocketTicketApi(dioClient: locator<DioClient>()),
  );

  /// Api Services
  locator.registerFactory(
    () => AuthApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
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
  locator.registerFactory(
    () => CartApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => WalletApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => PaymentApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => BookmarkApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => ChatApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => SupportApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => InquiryAPIService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => NotificationApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => OwnerOrderApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => ReservationApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => AnalyticsApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => AffiliateApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => ReferralApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => ProfileApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => BankApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(() => BankInfoCubit(api: locator<BankApiService>()));
  // Fresh socket per room (each ChatRoomBloc owns and closes one).
  locator.registerFactory(
    () => ChatSocket(ticketApi: locator<WebSocketTicketApi>()),
  );
  locator.registerFactory(
    () => DiscountApiService(dioClient: locator<DioClient>()),
  );
  locator.registerFactory(
    () => PublicMarketApiService(dioClient: locator<DioClient>()),
  );

  /// Repositories
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImp(locator<AuthApiService>()),
  );
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImp(locator<CategoryApiService>()),
  );
  locator.registerLazySingleton<CreateMarketRepository>(
    () => CreateMarketRepositoryImp(locator<CreateMarketApiService>()),
  );
  locator.registerLazySingleton<RegionRepository>(
    () => RegionRepositoryImp(locator<RegionApiServices>()),
  );
  locator.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImp(locator<ProductApiService>()),
  );
  locator.registerLazySingleton<ChatRepository>(
    () => ChatRepository(locator<ChatApiService>()),
  );
  locator.registerLazySingleton<InquiryRepo>(
    () => InquiryRepoImp(inquiryAPIService: locator<InquiryAPIService>()),
  );

  /// BLOCs
  locator.registerFactory(() => SplashBloc(locator<AuthSession>()));

  locator.registerFactory(
    () => AuthBloc(
      authRepository: locator<AuthRepository>(),
      authSession: locator<AuthSession>(),
    ),
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
  locator.registerFactory(() => VendorBloc(locator<CreateMarketRepository>()));
  locator.registerFactory(
    () => WorkspaceBloc(locator<CreateMarketRepository>()),
  );
  locator.registerFactory(() => AddProductBloc(locator<ProductRepository>()));
  locator.registerFactory(() => ThemeBloc());
  locator.registerFactory(
    () => MarketBloc(productRepository: locator<ProductRepository>()),
  );
  locator.registerFactory(
    () => CartBloc(cartApiService: locator<CartApiService>()),
  );
  locator.registerFactory(
    () => WalletBloc(walletApiService: locator<WalletApiService>()),
  );
  locator.registerFactory(
    () => PaymentBloc(paymentApiService: locator<PaymentApiService>()),
  );
  locator.registerFactory(
    () => BookmarkCubit(api: locator<BookmarkApiService>()),
  );
  locator.registerFactory(
    () => ChatListCubit(repository: locator<ChatRepository>()),
  );
  locator.registerFactory(() => InquiryBloc(locator<InquiryRepo>()));
  locator.registerFactory(() => InquiryListCubit(repo: locator<InquiryRepo>()));
  locator.registerFactory(
    () => ReservationBloc(api: locator<ReservationApiService>()),
  );
  locator.registerFactory(
    () => NotificationBloc(api: locator<NotificationApiService>()),
  );
}
