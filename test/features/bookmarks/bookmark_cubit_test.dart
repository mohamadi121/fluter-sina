import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/bookmarks/bloc/bookmark_cubit.dart';
import 'package:asood/features/bookmarks/data/bookmark_api_service.dart';

class _FakeBookmarkApi implements BookmarkApiService {
  dynamic listResult;
  dynamic toggleResult;
  final toggledIds = <String>[];

  @override
  Future list() async => listResult;

  @override
  Future toggle(String marketId) async {
    toggledIds.add(marketId);
    return toggleResult;
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
    api.toggleResult = Success(code: 200, message: 'bookmarked');

    await cubit.toggle('m9');

    expect(api.toggledIds, ['m9']);
    expect(cubit.state.isBookmarked('m9'), isTrue);
  });

  test('toggle reverts the flip when the call fails', () async {
    api.toggleResult = Failure(
      code: 500,
      errorResponse: 'x',
      kind: FailureKind.server,
    );

    await cubit.toggle('m9');

    expect(cubit.state.isBookmarked('m9'), isFalse);
    expect(cubit.state.error, 'x');
  });
}
