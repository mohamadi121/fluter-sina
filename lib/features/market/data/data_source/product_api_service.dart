import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/market/data/model/product_model.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ProductApiService {
  DioClient dioClient;
  ProductApiService({required this.dioClient});

  //get products
  Future getProducts(marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.ownerProductListById}$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  //get product by id
  Future getProductById(productId) async {
    var uri = 'owner/product/detail/$productId/';
    try {
      Response res = await dioClient.getData(uri);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  // create product

  Future createProduct(ProductModel product) async {
    List<MultipartBody> images = [];

    // Handle multiple images
    if (product.image != null && product.image!.isNotEmpty) {
      for (XFile image in product.image!) {
        images.add(MultipartBody('uploaded_images', image));
      }
    }
    try {
      Response res = await dioClient.postMultipartData(
        Endpoints.createProduct,
        product.toJson(),
        images,
      );

      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  //get product comments
  Future getProductComments(productId) async {
    try {
      Response res = await dioClient.getData(
        '${Endpoints.productCommentById}/$productId/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future createMarketTheme(String marketId, int order) async {
    try {
      Response res = await dioClient.postData(
        "${Endpoints.ownerProductThemeCreate}$marketId/",
        {"name": "test", "order": order},
      );

      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future getMarketTheme(String marketId) async {
    try {
      Response res = await dioClient.getData(
        "${Endpoints.ownerProductThemeList}$marketId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future updateMarketTheme(
    String productId,
    String themeId,
    String themeIndex,
  ) async {
    try {
      Response res = await dioClient.putData(
        "${Endpoints.ownerProductThemeUpdate}$themeId/",
        {"product": productId, "index": int.parse(themeIndex)},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future deleteMarketTheme(String themeId) async {
    try {
      Response res = await dioClient.deleteData(
        "${Endpoints.baseProduct}/theme/delete/$themeId/",
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// POST user/comment/create/ — bare `{"message", "id"}` with 201.
  /// content_type: 'product' | 'market'; parentId for replies.
  Future createComment({
    required String contentType,
    required String objectId,
    required String comment,
    int? parentId,
  }) async {
    try {
      Response res = await dioClient.postData('user/comment/create/', {
        'content_type': contentType,
        'object_id': objectId,
        'comment': comment,
        if (parentId != null) 'parent_id': parentId,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
