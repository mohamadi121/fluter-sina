import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/notification/blocs/notification_bloc.dart';
import 'package:asood/features/notification/data/notification_api_service.dart';

class _FakeNotificationApi implements NotificationApiService {
  dynamic listRes;
  dynamic markRes;
  dynamic markAllRes;
  final marked = <String>[];

  @override
  Future list() async => listRes;

  @override
  Future markAsRead(String id) async {
    marked.add(id);
    return markRes;
  }

  @override
  Future markAllAsRead() async => markAllRes;

  @override
  Future unreadCount() async => throw UnimplementedError();

  @override
  DioClient get dioClient => throw UnimplementedError();
}

void main() {
  late _FakeNotificationApi api;
  late NotificationBloc bloc;

  setUp(() {
    api = _FakeNotificationApi();
    bloc = NotificationBloc(api: api);
  });

  tearDown(() => bloc.close());

  test('load maps list and computes unread count from read_at', () async {
    api.listRes = Success(
      code: 200,
      response: {
        'results': [
          {'id': 'n1', 'title': 'a', 'body': 'x', 'read_at': null},
          {
            'id': 'n2',
            'title': 'b',
            'body': 'y',
            'read_at': '2026-07-01T10:00:00Z',
          },
        ],
      },
    );

    bloc.add(const LoadNotifications());
    await bloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

    expect(bloc.state.notifications, hasLength(2));
    expect(bloc.state.unreadCount, 1);
  });

  test('mark read is optimistic and calls the api', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'n1', 'title': 'a', 'body': 'x', 'read_at': null},
      ],
    );
    bloc.add(const LoadNotifications());
    await bloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

    api.markRes = Success(code: 200, response: {});
    bloc.add(const MarkNotificationRead('n1'));
    await bloc.stream.firstWhere((s) => s.unreadCount == 0);

    expect(api.marked, ['n1']);
    expect(bloc.state.notifications.single.isRead, isTrue);
  });

  test('mark read reverts on api failure', () async {
    api.listRes = Success(
      code: 200,
      response: [
        {'id': 'n1', 'title': 'a', 'body': 'x', 'read_at': null},
      ],
    );
    bloc.add(const LoadNotifications());
    await bloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

    api.markRes = Failure(
      code: 500,
      errorResponse: 'x',
      kind: FailureKind.server,
    );
    bloc.add(const MarkNotificationRead('n1'));
    // optimistic true, then revert to false
    await bloc.stream.firstWhere(
      (s) => s.notifications.isNotEmpty && !s.notifications.single.isRead,
    );

    expect(bloc.state.notifications.single.isRead, isFalse);
  });

  test('load failure surfaces error', () async {
    api.listRes = Failure(
      code: 500,
      errorResponse: 'boom',
      kind: FailureKind.server,
    );

    bloc.add(const LoadNotifications());
    await bloc.stream.firstWhere((s) => s.status == NotificationStatus.failure);

    expect(bloc.state.error, 'boom');
  });
}
