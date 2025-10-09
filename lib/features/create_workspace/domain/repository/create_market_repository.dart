import 'package:asood/core/architecture/result.dart';
import 'package:asood/features/create_workspace/data/model/market_contact.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/models/theme_model.dart';

import 'package:asood/features/vendor/data/model/market_location_model.dart';

abstract class CreateMarketRepository {
  Future<Result<Map<String, dynamic>>> createMarketBase(
    String type,
    String businessId,
    String name,
    String description,
    String subCategory,
    String slogan,
  );

  Future<Result<Map<String, dynamic>>> createMarketContact(MarketContactModel marketContact);

  Future<Result<Map<String, dynamic>>> createMarketLocation(MarketLocationModel marketLocation);

  Future<Result<List<dynamic>>> getMarketList();

  Future<Result<Map<String, dynamic>>> inactiveMarket(marketId);

  Future<Result<Map<String, dynamic>>> queueMarket(marketId);

  Future<Result<List<dynamic>>> getMarketSliders(marketId);

  Future<Result<Map<String, dynamic>>> uploadMarketLogo(XFile imagesFile, String marketId);

  Future<Result<void>> deleteMarketLogo(marketId);

  Future<Result<Map<String, dynamic>>> uploadMarketBackground(XFile imagesFile, marketId);

  Future<Result<void>> deleteMarketBackground(marketId);

  Future<Result<Map<String, dynamic>>> uploadMarketSlider(marketId, XFile imagesFile);

  Future<Result<Map<String, dynamic>>> editMarketSlider(sliderId, XFile imagesFile);

  Future<Result<Map<String, dynamic>>> modifyMarketSlider(body, sliderId);

  Future<Result<void>> deleteMarketSlider(sliderId);

  Future<Result<Map<String, dynamic>>> setMarketTheme(String marketId, ThemeModel themeModel);

  Future<Result<List<dynamic>>> getMarketComments(marketId);

  Future<Result<Map<String, dynamic>>> createSchedule(scheduleMarketModel);
}
