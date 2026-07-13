import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Bank info (`api/v1/user/...`, Token auth).
class BankApiService {
  final DioClient dioClient;
  BankApiService({required this.dioClient});

  /// The list of selectable banks.
  Future banks() async {
    try {
      final Response res = await dioClient.getData('user/bank-info/list/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// The user's saved bank cards.
  Future myBankInfos() async {
    try {
      final Response res = await dioClient.getData('user/bank/info/list/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future create(Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.postData(
        'user/bank/info/create/',
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future update(String id, Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.putData(
        'user/bank/info/update/$id/',
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future delete(String id) async {
    try {
      final Response res = await dioClient.deleteData(
        'user/bank/info/delete/$id/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
