class Endpoints {
  Endpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.asoud.ir/api/v1/',
  );
  
  // Asset/Media base URLs - configurable for different environments
  static const String assetBaseUrl = String.fromEnvironment(
    'ASSET_BASE_URL',
    defaultValue: 'https://asoud.ir/',
  );
  
  static const String websiteBaseUrl = String.fromEnvironment(
    'WEBSITE_BASE_URL', 
    defaultValue: 'https://asoud.ir/',
  );

  // WebSocket URLs - configurable for different environments
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.asoud.ir/ws/',
  );
  
  /// WebSocket Endpoints
  static String wsNotifications = '${wsBaseUrl}notifications/';
  static String wsChat = '${wsBaseUrl}chat/';
  static String wsAnalytics = '${wsBaseUrl}analytics/';
  static String wsSmartHome = '${wsBaseUrl}smart-home/';
  static String wsDeviceControl = '${wsBaseUrl}device-control/';
  
  // static String baseUrl = 'http://5.34.201.94/api/v1/';

  static const Map<String, String> simpleHeader = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static String loginCreate = "user/pin/create/";
  static String loginVerify = 'user/pin/verify/';
  static String logout = "logout/";

  /// user
  static String userAdvertise = "advertisements/";
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
  static String productCommentById = 'user/comment/comments/product';

  /// region
  static String countryList = 'region/country/list/';

  /// this needs {{countryID}}
  static String provinceList = 'region/province/list/';

  /// this needs {{provinceID}}
  static String cityList = 'region/city/list/';

  /// inquiry
  static String inquiry = 'user/inquiries/';

  /// bank
  static String bankInfoList = 'user/bank-info/list/';  // Get available banks
  static String userBankInfoList = 'user/bank/info/list/';  // Get user's bank cards
  static String createBankInfo = 'user/bank/info/create/';  // Create new bank card
  static String updateBankInfo = 'user/bank/info/update/';  // Update bank card
  static String deleteBankInfo = 'user/bank/info/delete/';  // Delete bank card
  static String bankInfoDetail = 'user/bank/info/detail/';  // Get bank card details

  /// comment
  static String userCommentCreate = 'user/comment/create/';
  static String userCommentsByProduct = 'user/comment/comments/product/';  // Add product ID

  /// order
  static String userOrderAddItem = 'user/order/add_item/';
  static String userOrderList = 'user/order/orders/';
  static String userOrderUpdateItem = 'user/order/update_item/';  // Add order ID

  /// bookmark
  static String userMarketBookmark = 'user/market/bookmark/';  // GET/POST
  static String userMarketBookmarkDelete = 'user/market/bookmark/';  // Add market ID for DELETE

  /// product details
  static String ownerProductDetail = 'owner/product/detail/';  // Add product ID

  // Helper methods for building URLs
  static String getAssetUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$assetBaseUrl$path';
  }
  
  static String getWebsiteUrl([String? path]) {
    return path != null ? '$websiteBaseUrl$path' : websiteBaseUrl;
  }
  
  static String getStoreUrl(String storeLink) {
    return 'http://$storeLink.asoud.ir/';
  }

  /// WebSocket URL builders
  static String getChatWsUrl(String roomId) {
    return '${wsChat}$roomId/';
  }
  
  static String getSupportWsUrl(String ticketId) {
    return '${wsBaseUrl}support/$ticketId/';
  }
  
  static String getDeviceWsUrl(String deviceId) {
    return '${wsDeviceControl}$deviceId/';
  }
  
  static String getUserNotificationsWsUrl(String userId) {
    return '${wsNotifications}user/$userId/';
  }
}
