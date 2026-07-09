import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/create_workspace/domain/repository/create_market_repository.dart';
import 'package:asood/features/market/presentation/blocs/edit_market/edit_market_cubit.dart';

class _FakeMarketRepo implements CreateMarketRepository {
  dynamic marketRes;
  dynamic contactRes;
  dynamic locationRes;
  dynamic updateRes;
  final calls = <String>[];

  @override
  Future getMarket(String marketId) async {
    calls.add('getMarket:$marketId');
    return marketRes;
  }

  @override
  Future getMarketContact(String marketId) async => contactRes;

  @override
  Future getMarketLocation(String marketId) async => locationRes;

  @override
  Future updateMarket(String marketId, Map<String, dynamic> body) async {
    calls.add('updateMarket:$marketId');
    return updateRes;
  }

  @override
  Future updateMarketContact(String id, Map<String, dynamic> body) async {
    calls.add('updateContact:$id');
    return updateRes;
  }

  @override
  Future updateMarketLocation(String id, Map<String, dynamic> body) async {
    calls.add('updateLocation:$id');
    return updateRes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeMarketRepo repo;
  late EditMarketCubit cubit;

  setUp(() {
    repo = _FakeMarketRepo();
    cubit = EditMarketCubit(repo: repo);
  });

  tearDown(() => cubit.close());

  test('load fills market and tolerates missing contact/location', () async {
    repo.marketRes = Success(code: 200, response: {'name': 'shop'});
    repo.contactRes = Failure(
      code: 404,
      errorResponse: 'contact_not_found',
      kind: FailureKind.notFound,
    );
    repo.locationRes = Failure(
      code: 404,
      errorResponse: 'location_not_found',
      kind: FailureKind.notFound,
    );

    await cubit.load('m1');

    expect(cubit.state.status, EditMarketStatus.ready);
    expect(cubit.state.market['name'], 'shop');
    expect(cubit.state.contact, isNull);
    expect(cubit.state.location, isNull);
  });

  test('load failure on market detail surfaces the error', () async {
    repo.marketRes = Failure(
      code: 403,
      errorResponse: 'permission denied',
      kind: FailureKind.forbidden,
    );

    await cubit.load('m1');

    expect(cubit.state.status, EditMarketStatus.failure);
    expect(cubit.state.error, 'permission denied');
  });

  test('saveBasic uses the loaded market id and reports saved', () async {
    repo.marketRes = Success(code: 200, response: {'name': 'shop'});
    repo.contactRes = Success(code: 200, response: {});
    repo.locationRes = Success(code: 200, response: {});
    repo.updateRes = Success(code: 200, message: 'updated');

    await cubit.load('m7');
    await cubit.saveBasic({'name': 'new name'});

    expect(repo.calls, contains('updateMarket:m7'));
    expect(cubit.state.status, EditMarketStatus.saved);
  });

  test('save failure keeps backend detail', () async {
    repo.marketRes = Success(code: 200, response: {});
    repo.contactRes = Success(code: 200, response: {});
    repo.locationRes = Success(code: 200, response: {});
    repo.updateRes = Failure(
      code: 400,
      errorResponse: 'name is required',
      kind: FailureKind.validation,
    );

    await cubit.load('m7');
    await cubit.saveContact({});

    expect(cubit.state.status, EditMarketStatus.failure);
    expect(cubit.state.error, 'name is required');
  });
}
