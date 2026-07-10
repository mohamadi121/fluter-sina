import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/analytics/bloc/analytics_cubit.dart';
import 'package:asood/features/analytics/data/analytics_api_service.dart';

class _FakeAnalyticsApi implements AnalyticsApiService {
  dynamic dashboardRes;

  @override
  Future dashboard() async => dashboardRes;

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeAnalyticsApi api;
  late AnalyticsCubit cubit;

  setUp(() {
    api = _FakeAnalyticsApi();
    cubit = AnalyticsCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps dashboard data', () async {
    api.dashboardRes = Success(
      code: 200,
      response: {'total_orders': 12, 'total_revenue': '450000'},
    );

    await cubit.load();

    expect(cubit.state.status, AnalyticsStatus.loaded);
    expect(cubit.state.data['total_orders'], 12);
  });

  test('failure surfaces detail', () async {
    api.dashboardRes = Failure(
      code: 403,
      errorResponse: 'forbidden',
      kind: FailureKind.forbidden,
    );

    await cubit.load();

    expect(cubit.state.status, AnalyticsStatus.failure);
    expect(cubit.state.error, 'forbidden');
  });
}
