import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// User price-inquiry endpoints (`api/v1/user/inquiries/`, Token auth).
/// Flow: create -> upload image(s) -> send. List/detail/answers for viewing.
class InquiryAPIService {
  final DioClient dioClient;
  InquiryAPIService({required this.dioClient});

  String get _base => Endpoints.inquiry; // 'user/inquiries/'

  Future list() async {
    try {
      final Response res = await dioClient.getData(_base);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future detail(String id) async {
    try {
      final Response res = await dioClient.getData('$_base$id/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future answers(String id) async {
    try {
      final Response res = await dioClient.getData('$_base$id/answers/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future create(Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.postData('${_base}create/', body);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future update(String id, Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.putData('$_base$id/update/', body);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// Upload an image to an existing inquiry (multipart field name `images`).
  Future uploadImage(String id, XFile image) async {
    try {
      final Response res = await dioClient.postMultipartData(
        '$_base$id/image/',
        {},
        [MultipartBody('images', image)],
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// Finalize/broadcast an inquiry.
  Future send(String id) async {
    try {
      final Response res = await dioClient.postData('$_base$id/send/', {
        'send': true,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future renewExpiry(String id) async {
    try {
      final Response res = await dioClient.postData('$_base$id/expiry/', {});
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future delete(String id) async {
    try {
      final Response res = await dioClient.deleteData('$_base$id/delete/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
