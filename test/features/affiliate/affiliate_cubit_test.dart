import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/affiliate/bloc/affiliate_cubit.dart';
import 'package:asood/features/affiliate/data/affiliate_api_service.dart';

class _FakeAffiliateApi implements AffiliateApiService {
  dynamic availableRes;
  dynamic createRes;
  Map<String, dynamic>? lastCreate;

  @override
  Future availableProducts() async => availableRes;

  @override
  Future create(Map<String, dynamic> body) async {
    lastCreate = body;
    return createRes;
  }

  @override
  Future myProducts(String marketId) async => throw UnimplementedError();

  @override
  Future delete(String id) async => throw UnimplementedError();

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeAffiliateApi api;
  late AffiliateCubit cubit;

  setUp(() {
    api = _FakeAffiliateApi();
    cubit = AffiliateCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('loadAvailable maps products', () async {
    api.availableRes = Success(
      code: 200,
      response: [
        {'id': 'p1', 'name': 'کالا', 'main_price': '1000'},
      ],
    );

    await cubit.loadAvailable();

    expect(cubit.state.status, AffiliateStatus.loaded);
    expect(cubit.state.products.single['name'], 'کالا');
  });

  test('create sends body and reloads on success', () async {
    api.createRes = Success(code: 201, response: {'id': 'a1'});
    api.availableRes = Success(code: 200, response: []);

    final ok = await cubit.create({'product': 'p1', 'market': 'm1'});

    expect(ok, isTrue);
    expect(api.lastCreate!['product'], 'p1');
  });

  test('create failure returns false with error', () async {
    api.createRes = Failure(
      code: 400,
      errorResponse: 'bad',
      kind: FailureKind.validation,
    );

    final ok = await cubit.create({'product': 'p1'});

    expect(ok, isFalse);
    expect(cubit.state.error, 'bad');
  });
}
