import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:asood/features/market/presentation/blocs/bloc/market_bloc.dart';

class _FakeProductRepository implements ProductRepository {
  dynamic createThemeResult;
  dynamic listThemeResult;
  final creates = <MapEntry<String, int>>[];

  @override
  Future createMarketTheme(String marketId, int order) async {
    creates.add(MapEntry(marketId, order));
    return createThemeResult;
  }

  @override
  Future getMarketTheme(String marketId) async => listThemeResult;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeProductRepository repo;
  late MarketBloc bloc;

  setUp(() {
    repo = _FakeProductRepository();
    bloc = MarketBloc(productRepository: repo);
  });

  tearDown(() => bloc.close());

  test(
    'add theme reloads authoritative list and retains success feedback',
    () async {
      repo.createThemeResult = Success(
        code: 201,
        response: {'name': 'layout-3', 'order': 3},
      );
      repo.listThemeResult = Success(
        code: 200,
        response: [
          {'id': 'theme-1', 'name': 'layout-3', 'order': 3, 'products': []},
        ],
      );
      final completed = bloc.stream.firstWhere(
        (state) => state.status == CWSStatus.success,
      );

      bloc.add(const AddTemplateEvent(marketId: 'market-1', template: 3));
      final state = await completed;

      expect(repo.creates.single.key, 'market-1');
      expect(repo.creates.single.value, 3);
      expect(state.templateList.single.name, 'layout-3');
      expect(state.feedback, 'قالب با موفقیت اضافه شد');
    },
  );

  test('add theme failure remains visible with backend detail', () async {
    repo.createThemeResult = Failure(
      code: 400,
      errorResponse: 'Layout order is invalid',
      kind: FailureKind.validation,
    );
    final completed = bloc.stream.firstWhere(
      (state) => state.status == CWSStatus.failure,
    );

    bloc.add(const AddTemplateEvent(marketId: 'market-1', template: 18));
    final state = await completed;

    expect(state.feedback, 'Layout order is invalid');
  });
}
