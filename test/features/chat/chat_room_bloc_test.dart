import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/blocs/chat_room_bloc.dart';
import 'package:asood/features/chat/data/chat_api_service.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/chat_socket.dart';

import '../../core/auth/in_memory_token_storage.dart';

class _FakeChatApi implements ChatApiService {
  dynamic messagesRes;
  dynamic sendRes;
  String? lastSentContent;

  @override
  Future roomMessages(String roomId, {int page = 1, int pageSize = 50}) async =>
      messagesRes;

  @override
  Future sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) async {
    lastSentContent = content;
    return sendRes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeSocket extends ChatSocket {
  _FakeSocket() : super(authSession: AuthSession(InMemoryTokenStorage(null)));

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool connected = false;
  final sent = <String>[];

  @override
  Stream<Map<String, dynamic>> get frames => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  void connect(String roomId) => connected = true;

  @override
  void sendMessage(String content, {String messageType = 'text'}) =>
      sent.add(content);

  @override
  void sendTyping({required bool typing}) {}

  @override
  void markAsRead(String messageId) {}

  @override
  void disconnect() => connected = false;

  void emitFrame(Map<String, dynamic> frame) => _controller.add(frame);
}

void main() {
  late _FakeChatApi api;
  late _FakeSocket socket;
  late ChatRoomBloc bloc;

  setUp(() {
    api = _FakeChatApi();
    socket = _FakeSocket();
    bloc = ChatRoomBloc(repository: ChatRepository(api), socket: socket);
  });

  tearDown(() => bloc.close());

  Success emptyHistory() => Success(
    code: 200,
    response: {'results': [], 'count': 0, 'page': 1, 'page_size': 50},
  );

  test('LoadRoom loads history and opens the socket', () async {
    api.messagesRes = Success(
      code: 200,
      response: {
        'results': [
          {'id': 'm1', 'content': 'hi', 'sent_at': '2026-07-01T10:00:00Z'},
        ],
        'count': 1,
        'page': 1,
        'page_size': 50,
      },
    );

    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    expect(bloc.state.status, ChatRoomStatus.ready);
    expect(bloc.state.messages, hasLength(1));
    expect(socket.connected, isTrue);
  });

  test('connection_established sets live + current user id', () async {
    api.messagesRes = emptyHistory();
    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    socket.emitFrame({
      'type': 'connection_established',
      'user_id': 5,
      'room_id': 'r1',
    });
    await pumpEventQueue();

    expect(bloc.state.connection, ChatConnection.live);
    expect(bloc.state.currentUserId, 5);
  });

  test('chat_message frame appends and de-duplicates by id', () async {
    api.messagesRes = emptyHistory();
    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    final frame = {
      'type': 'chat_message',
      'message': {
        'id': 'm9',
        'sender_id': 9,
        'content': 'hello',
        'sent_at': '2026-07-01T10:00:00Z',
      },
    };
    socket.emitFrame(frame);
    socket.emitFrame(frame); // duplicate id
    await pumpEventQueue();

    expect(bloc.state.messages, hasLength(1));
    expect(bloc.state.messages.single.content, 'hello');
  });

  test('socket_closed flips connection to offline', () async {
    api.messagesRes = emptyHistory();
    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    socket.emitFrame({'type': 'socket_closed'});
    await pumpEventQueue();

    expect(bloc.state.connection, ChatConnection.offline);
  });

  test('send over the socket when connected', () async {
    api.messagesRes = emptyHistory();
    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    bloc.add(const SendChatMessage('salam'));
    await pumpEventQueue();

    expect(socket.sent, contains('salam'));
    expect(api.lastSentContent, isNull); // did not fall back to REST
  });

  test('falls back to REST send when the socket is down', () async {
    api.messagesRes = emptyHistory();
    bloc.add(const LoadRoom('r1'));
    await pumpEventQueue();

    socket.connected = false;
    api.sendRes = Success(
      code: 201,
      response: {
        'id': 'm2',
        'content': 'offline-msg',
        'sent_at': '2026-07-01T12:00:00Z',
      },
    );

    bloc.add(const SendChatMessage('offline-msg'));
    await pumpEventQueue();

    expect(api.lastSentContent, 'offline-msg');
    expect(bloc.state.messages.any((m) => m.content == 'offline-msg'), isTrue);
  });
}
