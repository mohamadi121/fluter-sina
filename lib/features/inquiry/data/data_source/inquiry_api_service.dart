import 'dart:io';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:dio/dio.dart';

class InquiryAPIService {
  DioClient dioClient;
  InquiryAPIService({required this.dioClient});

  Future submitInquiry(
    String inquiryType,
    String inquiryTitle,
    String? inquiryDescription,
    String? inquiryDetails,
    String inquiryCategory,
    double? inquiryAmount,
    String? inquiryUnit,
    String? inquiryName,
    List<File>? inquiryImages,
  ) async {
    var body = {};
    var uri = '';
    try {
      Response res = await dioClient.postData(uri, body);
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }
}
