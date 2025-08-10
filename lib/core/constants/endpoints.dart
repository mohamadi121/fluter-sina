import '../config/env_config.dart';

class Endpoints {
  Endpoints._();

  static String token = 'token';
  static String baseUrl = '${EnvConfig.baseUrl}/api/v1/';
  static String wsBaseUrl = EnvConfig.wsBaseUrl;

  static const Map<String, String> simpleHeader = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // ---------------- AUTH -----------------
  static String loginCreate = "user/pin/create/";
  static String loginVerify = 'user/pin/verify/';
  static String logout = "logout/";

  /// user
  static String userAdvertise = "advertise/";
  static String userContact = 'contact/';

  /// category
  static String categoryGroupList = 'category/group/list/';
  static String categoryList = 'category/list/';
  static String subCategoryList = 'category/sub/list/';

  /// market
  static String baseMarket = 'owner/market';
  static String ownerMarketList = '$baseMarket/list/';
  static String ownerCreateMarket = '$baseMarket/create/';
  static String ownerCreateMarketContect = '$baseMarket/contact/create/';
  static String ownerSlider = '$baseMarket/slider';
  static String ownerDeleteBg = '$baseMarket/background';
  static String ownerTheme = '$baseMarket/theme';
  static String ownerCommentList = '$baseMarket/comment/list';
  static String ownerBackground = '$baseMarket/background';
  static String ownerLogo = '$baseMarket/logo';
  static String ownerQueue = '$baseMarket/queue';
  static String ownerInactive = '$baseMarket/inactive';
  static String ownerLocationCreate = '$baseMarket/location/create/';
  static String ownerCreateSchedule = '$baseMarket/schedules/create/';

  /// Product
  // owner
  static String baseProduct = 'owner/product';
  static String createProduct = '$baseProduct/create/';
  static String createProductDiscount = '$baseProduct/discount/create/';
  static String ownerProductListById = '$baseProduct/list/';
  static String ownerProductThemeCreate = '$baseProduct/theme/create/';
  static String ownerProductThemeList = '$baseProduct/theme/list/';
  static String ownerProductThemeUpdate = '$baseProduct/theme/update/';
  //user
  static String productCommentById = 'user/product/comment/list/';

  /// region
  static String countryList = 'region/country/list/';

  /// this needs {{countryID}}
  static String provinceList = 'region/province/list/';

  /// this needs {{provinceID}}
  static String cityList = 'region/city/list/';

  /// inquiry
  static String inquiry = 'region/city/list/';

  // ------------------------------------------------------------------
  // New helper methods (non-breaking) for clearer usage (doc v1.8)
  // ------------------------------------------------------------------

  // Auth
  static String pinCreate() => 'user/pin/create/';
  static String pinVerify() => 'user/pin/verify/';
  static String logoutUrl() => 'user/logout/'; // TODO: confirm final path

  // Categories
  static String categoryGroups() => 'category/group/list/';
  static String categoriesOfGroup(String groupId) => 'category/list/$groupId/';
  static String subCategoriesOf(String categoryId) => 'category/sub/list/$categoryId/';

  // Region
  static String countries() => 'region/country/list/';
  static String provinces(String countryId) => 'region/province/list/$countryId/';
  static String cities(String provinceId) => 'region/city/list/$provinceId/';

  // Market Owner
  static String marketCreate() => 'owner/market/create/';
  static String marketDetailOwner(String id) => 'owner/market/detail/$id/';
  static String marketUpdate(String id) => 'owner/market/update/$id/';
  static String marketListOwner() => 'owner/market/list/';
  static String marketLogo(String id) => 'owner/market/logo/$id/';
  static String marketBackground(String id) => 'owner/market/background/$id/';
  static String marketSliderCreate(String id) => 'owner/market/slider/create/$id/';
  static String marketTheme(String id) => 'owner/market/theme/$id/';
  static String marketInactive(String id) => 'owner/market/inactive/$id/';
  static String marketQueue(String id) => 'owner/market/queue/$id/';
  static String marketLocationCreate() => 'owner/market/location/create/';
  static String marketScheduleCreate() => 'owner/market/schedules/create/';

  // Market User
  static String marketListUser() => 'user/market/list/';
  static String marketDetailUser(String id) => 'user/market/detail/$id/';
  static String marketBookmark(String id) => 'user/market/bookmark/$id/';
  static String marketReport(String id) => 'user/market/report/$id/';

  // Product Owner
  static String productCreate() => 'owner/product/create/';
  static String productListOwner(String marketId) => 'owner/product/list/$marketId/';
  static String productDetailOwner(String productId) => 'owner/product/detail/$productId/';
  static String productDiscountCreate(String productId) => 'owner/product/discount/create/$productId/';

  // Product User
  static String productListUser(String marketId) => 'user/product/list/$marketId/';
  static String productDetailUser(String productId) => 'user/product/detail/$productId/';
  static String productBookmark(String productId) => 'user/product/bookmark/$productId/';
  static String productReport(String productId) => 'user/product/report/$productId/';

  // Discount
  static String discountCreate() => 'discount/owner/create/';
  static String discountListOwner() => 'discount/owner/list/';
  static String discountDetail(String id) => 'discount/owner/$id/';
  static String discountDelete(String id) => 'discount/owner/delete/$id/';
  static String discountValidate() => 'discount/user/validate/';

  // Comment
  static String commentCreate() => 'user/comment/create/';
  static String commentDetail(String id) => 'user/comment/$id';
  static String commentList(String contentType, String objectId) => 'user/comment/comments/$contentType/$objectId';
  static String commentUpdate(String id) => 'user/comment/update/$id';

  // Advertisement
  static String advertisementCreate() => 'advertisements/create';
  static String advertisementList() => 'advertisements/';
  static String advertisementDetail(String id) => 'advertisements/$id';
  static String advertisementUpdate(String id) => 'advertisements/$id/update';
  static String advertisementDelete(String id) => 'advertisements/$id/delete';

  // Wallet
  static String walletBalance() => 'wallet/balance/';
  static String walletBalanceCheck() => 'wallet/balance/check/';
  static String walletPay() => 'wallet/pay/';

  // Payment
  static String paymentCreate() => 'user/payments/create/';
  static String paymentList() => 'user/payments/';
  static String paymentDetail(String id) => 'user/payments/$id/';

  // Order User
  static String orderCreateUser() => 'user/order/create/';
  static String orderListUser() => 'user/order/list/';
  static String orderDetailUser(String id) => 'user/order/detail/$id/';

  // Order Owner
  static String orderVerifyOwner(String id) => 'owner/order/verify/$id/';
  static String orderListOwner() => 'owner/order/list/';
  static String orderDetailOwner(String id) => 'owner/order/detail/$id/';
}
