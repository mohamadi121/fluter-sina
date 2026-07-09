import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/bloc/discount_cubit.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/data/discount_api_service.dart';

class _FakeDiscountApi implements DiscountApiService {
  dynamic listRes;
  dynamic createRes;
  dynamic deleteRes;
  Map<String, dynamic>? lastCreateBody;

  @override
  Future list() async => listRes;

  @override
  Future create(Map<String, dynamic> body) async {
    lastCreateBody = body;
    return createRes;
  }

  @override
  Future delete(String discountId) async => deleteRes;

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeDiscountApi api;
  late DiscountCubit cubit;

  setUp(() {
    api = _FakeDiscountApi();
    cubit = DiscountCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps envelope list', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'd1', 'code': 'OFF10', 'percentage': 10},
      ],
    );

    await cubit.load();

    expect(cubit.state.status, DiscountStatus.loaded);
    expect(cubit.state.discounts.single['code'], 'OFF10');
  });

  test('create sends the backend contract fields and reloads', () async {
    api.createRes = Success(code: 201, message: 'created');
    api.listRes = Success(code: 200, response: []);

    await cubit.create(
      contentType: 'market',
      objectId: 'm1',
      percentage: 15,
      expiry: DateTime(2026, 8, 1),
      limitation: 5,
    );

    expect(api.lastCreateBody!['content_type'], 'market');
    expect(api.lastCreateBody!['object_id'], 'm1');
    expect(api.lastCreateBody!['percentage'], 15);
    expect(api.lastCreateBody!['limitation'], 5);
    expect(api.lastCreateBody!['expiry'], startsWith('2026-08-01'));
  });

  test('create failure keeps backend detail', () async {
    api.createRes = Failure(
      code: 400,
      errorResponse: 'invalid percentage',
      kind: FailureKind.validation,
    );

    await cubit.create(
      contentType: 'market',
      objectId: 'm1',
      percentage: 900,
      expiry: DateTime(2026, 8, 1),
    );

    expect(cubit.state.status, DiscountStatus.failure);
    expect(cubit.state.error, 'invalid percentage');
  });

  test('delete removes the row locally on success', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'd1'},
        {'id': 'd2'},
      ],
    );
    await cubit.load();
    api.deleteRes = Success(code: 200, message: 'deleted');

    await cubit.delete('d1');

    expect(cubit.state.discounts.single['id'], 'd2');
  });
}
