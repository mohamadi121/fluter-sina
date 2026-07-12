import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// User-side reservation endpoints (`api/v1/reservation/user/`, Token auth).
/// Booking flow: pick market -> services(?market) -> reserve-times(?service)
/// -> POST reservation/create {reserve, specialist}.
class ReservationApiService {
  final DioClient dioClient;
  ReservationApiService({required this.dioClient});

  static const String _base = 'reservation/user/';

  Future services(String marketId) async {
    try {
      final Response res = await dioClient.getData(
        '${_base}service/',
        queryParameters: {'market': marketId},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future specialists(String serviceId) async {
    try {
      final Response res = await dioClient.getData(
        '${_base}specialist/',
        queryParameters: {'service': serviceId},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future reserveTimes(String serviceId) async {
    try {
      final Response res = await dioClient.getData(
        '${_base}reserve-time/',
        queryParameters: {'service': serviceId},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future myReservations() async {
    try {
      final Response res = await dioClient.getData('${_base}reservation/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future createReservation({
    required String reserveTimeId,
    required String specialistId,
  }) async {
    try {
      final Response res = await dioClient
          .postData('${_base}reservation/create', {
            'reserve': reserveTimeId,
            'specialist': specialistId,
          });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
