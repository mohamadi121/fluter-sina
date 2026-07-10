import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/cart/data/data_source/owner_order_api_service.dart';
import 'package:asood/features/cart/presentation/bloc/owner_orders_cubit.dart';

class _FakeOwnerOrderApi implements OwnerOrderApiService {
  dynamic listRes;
  dynamic verifyRes;
  Map<String, dynamic>? lastVerify;

  @override
  Future list() async => listRes;

  @override
  Future verify({
    required String id,
    required bool verified,
    String description = '',
  }) async {
    lastVerify = {'id': id, 'verified': verified, 'description': description};
    return verifyRes;
  }

  @override
  Future detail(String id) async => throw UnimplementedError();

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeOwnerOrderApi api;
  late OwnerOrdersCubit cubit;

  setUp(() {
    api = _FakeOwnerOrderApi();
    cubit = OwnerOrdersCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps orders (bare list)', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'o1', 'total': 15000, 'is_paid': true},
      ],
    );

    await cubit.load();

    expect(cubit.state.status, OwnerOrdersStatus.loaded);
    expect(cubit.state.orders.single['id'], 'o1');
  });

  test('verify sends the contract fields and reloads', () async {
    api.verifyRes = Success(code: 200, message: 'ok');
    api.listRes = Success(code: 200, response: []);

    final ok = await cubit.verify(id: 'o1', verified: true, description: 'ok');

    expect(ok, isTrue);
    expect(api.lastVerify, {'id': 'o1', 'verified': true, 'description': 'ok'});
  });

  test('verify failure returns false and keeps error', () async {
    api.verifyRes = Failure(
      code: 400,
      errorResponse: 'invalid status',
      kind: FailureKind.validation,
    );

    final ok = await cubit.verify(id: 'o1', verified: false);

    expect(ok, isFalse);
    expect(cubit.state.error, 'invalid status');
  });

  test('load failure surfaces detail', () async {
    api.listRes = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    await cubit.load();

    expect(cubit.state.status, OwnerOrdersStatus.failure);
    expect(cubit.state.error, 'boom');
  });
}
