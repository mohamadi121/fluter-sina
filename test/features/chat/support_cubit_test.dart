import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/blocs/support_cubit.dart';
import 'package:asood/features/chat/data/support_api_service.dart';

class _FakeSupportApi implements SupportApiService {
  dynamic ticketsRes;
  dynamic createRes;
  Map<String, dynamic>? lastCreate;

  @override
  Future tickets() async => ticketsRes;

  @override
  Future createTicket({
    required String subject,
    required String description,
    String category = 'general',
    String priority = 'medium',
  }) async {
    lastCreate = {
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
    };
    return createRes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeSupportApi api;
  late SupportCubit cubit;

  setUp(() {
    api = _FakeSupportApi();
    cubit = SupportCubit(api: api);
  });

  tearDown(() => cubit.close());

  test('load maps ticket list', () async {
    api.ticketsRes = Success(
      code: 200,
      response: [
        {'id': 't1', 'subject': 'مشکل', 'status': 'open'},
      ],
    );

    await cubit.load();

    expect(cubit.state.status, SupportStatus.loaded);
    expect(cubit.state.tickets.single['subject'], 'مشکل');
  });

  test('create sends fields, returns chat_room_id, and reloads', () async {
    api.createRes = Success(
      code: 201,
      response: {'id': 't2', 'chat_room_id': 'room-99'},
    );
    api.ticketsRes = Success(code: 200, response: []);

    final roomId = await cubit.create(subject: 'کمک', description: 'توضیح');

    expect(roomId, 'room-99');
    expect(api.lastCreate!['subject'], 'کمک');
    expect(api.lastCreate!['category'], 'general');
  });

  test('create failure returns null and surfaces error', () async {
    api.createRes = Failure(
      code: 400,
      errorResponse: 'subject too short',
      kind: FailureKind.validation,
    );

    final roomId = await cubit.create(subject: 'x', description: 'y');

    expect(roomId, isNull);
    expect(cubit.state.status, SupportStatus.failure);
    expect(cubit.state.error, 'subject too short');
  });
}
