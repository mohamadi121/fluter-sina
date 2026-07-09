import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/customer/data/public_market_api_service.dart';
import 'package:asood/features/customer/presentation/blocs/public_markets/public_markets_cubit.dart';

class _FakePublicMarketApi implements PublicMarketApiService {
  dynamic listRes;
  String? lastSearch;

  @override
  Future list({String? search}) async {
    lastSearch = search;
    return listRes;
  }

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakePublicMarketApi api;
  late PublicMarketsCubit cubit;

  setUp(() {
    api = _FakePublicMarketApi();
    cubit = PublicMarketsCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps public market list and passes search term', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'm1', 'name': 'فروشگاه یک'},
      ],
    );

    await cubit.load(search: 'ابزار');

    expect(api.lastSearch, 'ابزار');
    expect(cubit.state.status, PublicMarketsStatus.loaded);
    expect(cubit.state.markets.single.name, 'فروشگاه یک');
  });

  test('failure surfaces backend detail', () async {
    api.listRes = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    await cubit.load();

    expect(cubit.state.status, PublicMarketsStatus.failure);
    expect(cubit.state.error, 'boom');
  });
}
