import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/data/chat_api_service.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/blocs/chat_list_cubit.dart';

class _FakeChatApi implements ChatApiService {
  dynamic roomsRes;

  @override
  Future rooms() async => roomsRes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeChatApi api;
  late ChatListCubit cubit;

  setUp(() {
    api = _FakeChatApi();
    cubit = ChatListCubit(repository: ChatRepository(api));
  });

  tearDown(() => cubit.close());

  test('parses a paginated {results:[...]} room list', () async {
    api.roomsRes = Success(
      code: 200,
      response: {
        'results': [
          {'id': 'r1', 'name': 'اتاق ۱', 'unread_count': 2},
        ],
        'count': 1,
      },
    );

    await cubit.load();

    expect(cubit.state.status, ChatListStatus.loaded);
    expect(cubit.state.rooms.single.name, 'اتاق ۱');
    expect(cubit.state.rooms.single.unreadCount, 2);
  });

  test('parses a bare list room response', () async {
    api.roomsRes = Success(
      code: 200,
      response: [
        {'id': 'r1', 'name': 'a'},
        {'id': 'r2', 'name': 'b'},
      ],
    );

    await cubit.load();

    expect(cubit.state.rooms, hasLength(2));
  });

  test('failure surfaces backend detail', () async {
    api.roomsRes = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    await cubit.load();

    expect(cubit.state.status, ChatListStatus.failure);
    expect(cubit.state.error, 'boom');
  });
}
