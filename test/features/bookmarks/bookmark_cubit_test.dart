import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/bookmarks/bloc/bookmark_cubit.dart';
import 'package:asood/features/bookmarks/data/bookmark_api_service.dart';

class _FakeBookmarkApi implements BookmarkApiService {
  dynamic listResult;
  dynamic updateResult;
  Future<dynamic> Function(String marketId, bool bookmarked)? updateHandler;
  final updates = <MapEntry<String, bool>>[];

  @override
  Future list() async => listResult;

  @override
  Future setBookmarked(String marketId, bool bookmarked) async {
    updates.add(MapEntry(marketId, bookmarked));
    if (updateHandler != null) {
      return updateHandler!(marketId, bookmarked);
    }
    return updateResult;
  }

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeBookmarkApi api;
  late BookmarkCubit cubit;

  setUp(() {
    api = _FakeBookmarkApi();
    cubit = BookmarkCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load fills markets and bookmarked ids from envelope data', () async {
    api.listResult = Success(
      code: 200,
      response: [
        {'id': 'm1', 'name': 'store one'},
        {'id': 'm2', 'name': 'store two'},
      ],
    );

    await cubit.load();

    expect(cubit.state.status, BookmarkStatus.loaded);
    expect(cubit.state.markets, hasLength(2));
    expect(cubit.state.isBookmarked('m1'), isTrue);
    expect(cubit.state.isBookmarked('m3'), isFalse);
  });

  test('load failure keeps error message', () async {
    api.listResult = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    await cubit.load();

    expect(cubit.state.status, BookmarkStatus.failure);
    expect(cubit.state.error, 'boom');
  });

  test('toggle is optimistic and keeps the flip on success', () async {
    api.updateResult = Success(
      code: 200,
      response: {'market_id': 'm9', 'bookmarked': true},
    );

    await cubit.toggle('m9');

    expect(api.updates.single.key, 'm9');
    expect(api.updates.single.value, isTrue);
    expect(cubit.state.isBookmarked('m9'), isTrue);
    expect(cubit.state.pendingIds, isEmpty);
  });

  test('removal drops the market from the visible list', () async {
    api.listResult = Success(
      code: 200,
      response: [
        {'id': 'm1', 'name': 'store one'},
      ],
    );
    await cubit.load();
    api.updateResult = Success(
      code: 200,
      response: {'market_id': 'm1', 'bookmarked': false},
    );

    await cubit.toggle('m1');

    expect(cubit.state.markets, isEmpty);
    expect(cubit.state.isBookmarked('m1'), isFalse);
  });

  test(
    'authoritative bookmarked response restores an optimistically removed row',
    () async {
      api.listResult = Success(
        code: 200,
        response: [
          {'id': 'm1', 'name': 'store one'},
        ],
      );
      await cubit.load();
      api.updateResult = Success(
        code: 200,
        response: {'market_id': 'm1', 'bookmarked': true},
      );

      await cubit.toggle('m1');

      expect(cubit.state.markets.single.id, 'm1');
      expect(cubit.state.isBookmarked('m1'), isTrue);
    },
  );

  test('toggle failure restores both id and removed market', () async {
    api.listResult = Success(
      code: 200,
      response: [
        {'id': 'm1', 'name': 'store one'},
      ],
    );
    await cubit.load();
    api.updateResult = Failure(
      code: 500,
      errorResponse: 'x',
      kind: FailureKind.server,
    );

    await cubit.toggle('m1');

    expect(cubit.state.isBookmarked('m1'), isTrue);
    expect(cubit.state.markets.single.id, 'm1');
    expect(cubit.state.error, 'x');
    expect(cubit.state.pendingIds, isEmpty);
  });

  test(
    'concurrent updates for different markets do not overwrite each other',
    () async {
      api.listResult = Success(
        code: 200,
        response: [
          {'id': 'm1', 'name': 'store one'},
          {'id': 'm2', 'name': 'store two'},
        ],
      );
      await cubit.load();
      final firstResult = Completer<dynamic>();
      final secondResult = Completer<dynamic>();
      api.updateHandler =
          (marketId, bookmarked) =>
              marketId == 'm1' ? firstResult.future : secondResult.future;

      final first = cubit.toggle('m1');
      final second = cubit.toggle('m2');
      expect(cubit.state.markets, isEmpty);

      firstResult.complete(
        Success(code: 200, response: {'market_id': 'm1', 'bookmarked': false}),
      );
      await first;
      expect(cubit.state.markets, isEmpty);

      secondResult.complete(
        Failure(
          code: 500,
          errorResponse: 'failed m2',
          kind: FailureKind.server,
        ),
      );
      await second;

      expect(cubit.state.markets.map((market) => market.id), ['m2']);
      expect(cubit.state.isBookmarked('m1'), isFalse);
      expect(cubit.state.isBookmarked('m2'), isTrue);
      expect(cubit.state.pendingIds, isEmpty);
    },
  );
}
