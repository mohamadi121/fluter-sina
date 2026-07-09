import 'package:asood/features/create_workspace/data/model/market_contact.dart';
import 'package:asood/features/create_workspace/data/model/market_schedule.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/models/theme_model.dart';

import 'package:asood/features/vendor/data/model/market_location_model.dart';

class CreateMarketApiService {
  DioClient dioClient;
  CreateMarketApiService({required this.dioClient});

  // Create market base
  Future createMarketBase(
    String type,
    String businessId,
    String name,
    String description,
    String subCategory,
    String slogan,
    String? nationalCode,
  ) async {
    var body = {
      "type": type,
      "business_id": businessId,
      "name": name,
      "description": description,
      "sub_category": subCategory,
      "slogan": slogan,
      "national_code": nationalCode ?? "",
      "payment_gateway_type": "asoud",
    };
    try {
      Response res = await dioClient.postData(
        Endpoints.ownerCreateMarket,
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Create contact information
  Future createMarketContact(MarketContactModel marketContact) async {
    var body = {
      "market": marketContact.market,
      "first_mobile_number": marketContact.firstMobileNumber,
      "second_mobile_number": marketContact.secondMobileNumber,
      "telephone": marketContact.telephone,
      "fax": marketContact.fax,
      "email": marketContact.email,
      "website_url": marketContact.websiteUrl,

      "telegram_id": marketContact.messengerIds.telegram,
    };

    try {
      Response res = await dioClient.postData(
        Endpoints.ownerCreateMarketContect,
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Create market location
  Future createMarketLocation(MarketLocationModel marketLocation) async {
    var body = {
      "market": marketLocation.market,
      "city": marketLocation.city,
      "address": marketLocation.address,
      "zip_code": marketLocation.zipCode,
      "latitude": marketLocation.latitude,
      "longitude": marketLocation.longitude,
    };

    try {
      Response res = await dioClient.postData(
        Endpoints.ownerLocationCreate,
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Get market list
  Future getMarketList() async {
    try {
      Response res = await dioClient.getData(Endpoints.ownerMarketList);

      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Inactive market
  Future inactiveMarket(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.ownerInactive}/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Queue market
  Future queueMarket(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.ownerQueue}/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Upload market logo
  Future uploadMarketLogo(XFile imagesFile, marketId) async {
    List<MultipartBody> images = [MultipartBody('logo_img', imagesFile)];
    try {
      Response res = await dioClient.postMultipartData(
        "${Endpoints.ownerLogo}/$marketId/",
        {},
        images,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Delete market logo
  Future deleteMarketLogo(String marketId) async {
    try {
      Response res = await dioClient.deleteData(
        "${Endpoints.ownerLogo}/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Upload market background
  Future uploadMarketBackground(XFile imagesFile, String marketId) async {
    List<MultipartBody> images = [MultipartBody('background_img', imagesFile)];
    try {
      Response res = await dioClient.postMultipartData(
        "${Endpoints.ownerBackground}/$marketId/",
        {},
        images,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Delete market background
  Future deleteMarketBackground(String marketId) async {
    try {
      Response res = await dioClient.deleteData(
        "${Endpoints.ownerDeleteBg}/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Get market slider by id
  Future getMarketSlider(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.ownerSlider}/$marketId/",
      );

      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Create new slider by id
  Future createMarketSlider(String marketId, XFile imagesFile) async {
    List<MultipartBody> images = [MultipartBody('slider_img', imagesFile)];
    try {
      Response res = await dioClient.postMultipartData(
        "${Endpoints.ownerSlider}/$marketId/",
        {},
        images,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Edit slider by id
  Future editMarketSlider(String sliderId, XFile imagesFile) async {
    List<MultipartBody> images = [MultipartBody('slider_img', imagesFile)];
    try {
      Response res = await dioClient.patchMultipartData(
        "${Endpoints.ownerSlider}/$sliderId/",
        {},
        images,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Modify slider by slider id
  Future modifyMarketSlider(Map<String, dynamic> body, String sliderId) async {
    try {
      Response res = await dioClient.patchData(
        "${Endpoints.ownerSlider}/$sliderId/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Delete slider by id
  Future deleteMarketSlider(String sliderId) async {
    try {
      Response res = await dioClient.deleteData(
        "${Endpoints.ownerSlider}/$sliderId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Set market theme
  Future setMarketTheme(String marketId, ThemeModel themeModel) async {
    var body = {
      "color": themeModel.color,
      "background_color": themeModel.backgroundColor,
      "secondary_color": themeModel.secondaryColor,
      "font_color": themeModel.fontColor,
      "font": themeModel.font,
      "secondary_font_color": themeModel.secondaryFontColor,
    };
    try {
      Response res = await dioClient.postData(
        "${Endpoints.ownerTheme}/$marketId/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Get market comments (generic comments API, bare-list response)
  Future getMarketComments(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.commentsBase}/market/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Market detail (owner)
  Future getMarket(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.baseMarket}/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Market update (owner)
  Future updateMarket(String marketId, Map<String, dynamic> body) async {
    try {
      Response res = await dioClient.putData(
        "${Endpoints.baseMarket}/update/$marketId/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Market contact detail / update
  Future getMarketContact(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.baseMarket}/contact/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future updateMarketContact(
    String contactId,
    Map<String, dynamic> body,
  ) async {
    try {
      Response res = await dioClient.putData(
        "${Endpoints.baseMarket}/contact/update/$contactId/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Market location detail / update
  Future getMarketLocation(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.baseMarket}/location/$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future updateMarketLocation(
    String locationId,
    Map<String, dynamic> body,
  ) async {
    try {
      Response res = await dioClient.putData(
        "${Endpoints.baseMarket}/location/update/$locationId/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // Schedules list / update / delete
  Future getSchedules() async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.baseMarket}/schedules/list/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future updateSchedule(String scheduleId, Map<String, dynamic> body) async {
    try {
      Response res = await dioClient.putData(
        "${Endpoints.baseMarket}/schedules/$scheduleId/update/",
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future deleteSchedule(String scheduleId) async {
    try {
      Response res = await dioClient.deleteData(
        "${Endpoints.baseMarket}/schedules/$scheduleId/delete/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // post schedule
  Future setSchedule(MarketScheduleModel marketSchedule) async {
    try {
      Response res = await dioClient.postData(
        Endpoints.ownerCreateSchedule,
        marketSchedule.toJson(),
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
