import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/blocs/chat_membership_cubit.dart';
import 'package:asood/features/chat/data/chat_api_service.dart';
import 'package:asood/features/chat/data/chat_repository.dart';

class _FakeChatApi implements ChatApiService {
  dynamic participantsResult;
  dynamic mutationResult;
  String? addedMobile;
  String? addedRole;
  int? transferredUserId;

  @override
  Future participants(String roomId) async => participantsResult;

  @override
  Future addParticipant(
    String roomId, {
    required String mobileNumber,
    String role = 'member',
  }) async {
    addedMobile = mobileNumber;
    addedRole = role;
    return mutationResult;
  }

  @override
  Future transferOwnership(String roomId, int userId) async {
    transferredUserId = userId;
    return mutationResult;
  }

  @override
  Future leaveRoom(String roomId) async => mutationResult;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeChatApi api;
  late ChatMembershipCubit cubit;

  setUp(() {
    api = _FakeChatApi();
    cubit = ChatMembershipCubit(repository: ChatRepository(api));
  });

  tearDown(() => cubit.close());

  test('load parses privacy-safe participant contract', () async {
    api.participantsResult = Success(
      code: 200,
      response: [
        {
          'id': 10,
          'user': 7,
          'username': 'کاربر ۷',
          'first_name': '',
          'last_name': '',
          'role': 'owner',
          'joined_at': '2026-07-01T10:00:00Z',
        },
      ],
    );

    await cubit.load('room-1');

    expect(cubit.state.status, ChatMembershipStatus.loaded);
    expect(cubit.state.participants.single.userId, 7);
    expect(cubit.state.participants.single.role, 'owner');
  });

  test('adding an admin reloads authoritative membership list', () async {
    api.participantsResult = Success(code: 200, response: const []);
    api.mutationResult = Success(code: 201, response: const {});
    await cubit.load('room-1');

    final success = await cubit.add(mobileNumber: '09120000000', role: 'admin');

    expect(success, isTrue);
    expect(api.addedMobile, '09120000000');
    expect(api.addedRole, 'admin');
    expect(cubit.state.busy, isFalse);
  });

  test(
    'ownership transfer and leave expose successful terminal states',
    () async {
      api.participantsResult = Success(code: 200, response: const []);
      api.mutationResult = Success(code: 200, response: const {});
      await cubit.load('room-1');

      expect(await cubit.transfer(9), isTrue);
      expect(api.transferredUserId, 9);
      expect(await cubit.leave(), isTrue);
      expect(cubit.state.leftRoom, isTrue);
    },
  );

  test('mutation failure keeps the loaded participant list', () async {
    api.participantsResult = Success(
      code: 200,
      response: const [
        {'id': 1, 'user': 2, 'username': 'member', 'role': 'member'},
      ],
    );
    await cubit.load('room-1');
    api.mutationResult = Failure(
      code: 409,
      errorResponse: 'participant_limit_reached',
      kind: FailureKind.validation,
    );

    expect(await cubit.add(mobileNumber: '09120000000'), isFalse);
    expect(cubit.state.status, ChatMembershipStatus.loaded);
    expect(cubit.state.participants, hasLength(1));
    expect(cubit.state.error, 'participant_limit_reached');
  });
}
