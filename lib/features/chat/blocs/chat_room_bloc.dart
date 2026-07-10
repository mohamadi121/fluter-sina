import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/chat_socket.dart';
import 'package:asood/features/chat/data/models/chat_message_model.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';

/// One chat room. History comes over REST (paginated); live messages, typing
/// and presence come over the WebSocket. Sending prefers the socket and falls
/// back to REST when it is not connected.
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository repository;
  final ChatSocket socket;

  StreamSubscription<Map<String, dynamic>>? _frameSub;

  ChatRoomBloc({required this.repository, required this.socket})
    : super(const ChatRoomState()) {
    on<LoadRoom>(_onLoadRoom);
    on<LoadMoreMessages>(_onLoadMore);
    on<SendChatMessage>(_onSend);
    on<SetTyping>(_onSetTyping);
    on<FrameReceived>(_onFrame);
  }

  Future<void> _onLoadRoom(LoadRoom event, Emitter<ChatRoomState> emit) async {
    emit(
      state.copyWith(
        status: ChatRoomStatus.loading,
        roomId: event.roomId,
        connection: ChatConnection.connecting,
      ),
    );

    final res = await repository.roomMessages(event.roomId, page: 1);
    if (res is! Success) {
      emit(
        state.copyWith(
          status: ChatRoomStatus.failure,
          error: res is Failure ? res.message : 'خطا در دریافت پیام‌ها',
        ),
      );
      return;
    }

    final parsed = _parsePage(res.response);
    emit(
      state.copyWith(
        status: ChatRoomStatus.ready,
        messages: _sorted(parsed.messages),
        page: 1,
        hasMore: parsed.hasMore,
      ),
    );

    // Open the live socket and pipe frames back in as events.
    socket.connect(event.roomId);
    _frameSub?.cancel();
    _frameSub = socket.frames.listen((frame) => add(FrameReceived(frame)));
  }

  Future<void> _onLoadMore(
    LoadMoreMessages event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));

    final nextPage = state.page + 1;
    final res = await repository.roomMessages(state.roomId, page: nextPage);
    if (res is! Success) {
      emit(state.copyWith(loadingMore: false));
      return;
    }

    final parsed = _parsePage(res.response);
    emit(
      state.copyWith(
        messages: _sorted([...parsed.messages, ...state.messages]),
        page: nextPage,
        hasMore: parsed.hasMore,
        loadingMore: false,
      ),
    );
  }

  Future<void> _onSend(
    SendChatMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) {
      return;
    }

    if (socket.isConnected) {
      socket.sendMessage(content);
      return; // echoed back via the chat_message frame
    }

    // Socket down — send over REST so the message still lands.
    emit(state.copyWith(sending: true));
    final res = await repository.sendMessageRest(
      roomId: state.roomId,
      content: content,
    );
    if (res is Success && res.response is Map) {
      final message = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(res.response as Map),
      );
      emit(
        state.copyWith(
          sending: false,
          messages: _sorted([...state.messages, message]),
        ),
      );
    } else {
      emit(
        state.copyWith(
          sending: false,
          error: res is Failure ? res.message : 'ارسال پیام ناموفق بود',
        ),
      );
    }
  }

  void _onSetTyping(SetTyping event, Emitter<ChatRoomState> emit) {
    if (socket.isConnected) {
      socket.sendTyping(typing: event.typing);
    }
  }

  void _onFrame(FrameReceived event, Emitter<ChatRoomState> emit) {
    final frame = event.frame;
    switch (frame['type']) {
      case 'connection_established':
        emit(
          state.copyWith(
            connection: ChatConnection.live,
            currentUserId: _asInt(frame['user_id']),
          ),
        );
        break;
      case 'chat_message':
        final data = frame['message'];
        if (data is Map) {
          final message = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(data),
          );
          emit(state.copyWith(messages: _sorted([...state.messages, message])));
        }
        break;
      case 'typing':
        emit(state.copyWith(otherTyping: true));
        break;
      case 'stop_typing':
        emit(state.copyWith(otherTyping: false));
        break;
      case 'socket_closed':
      case 'socket_error':
        emit(state.copyWith(connection: ChatConnection.offline));
        break;
      default:
        break;
    }
  }

  _ParsedPage _parsePage(dynamic data) {
    final results = data is Map ? data['results'] : data;
    final messages =
        results is List
            ? results
                .whereType<Map>()
                .map(
                  (e) =>
                      ChatMessageModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
            : <ChatMessageModel>[];
    // "has more" if the server reports more than we've seen.
    final count = data is Map ? _asInt(data['count']) : null;
    final page = data is Map ? _asInt(data['page']) ?? 1 : 1;
    final pageSize = data is Map ? _asInt(data['page_size']) ?? 50 : 50;
    final hasMore = count != null ? page * pageSize < count : false;
    return _ParsedPage(messages, hasMore);
  }

  List<ChatMessageModel> _sorted(List<ChatMessageModel> messages) {
    final unique = <String, ChatMessageModel>{};
    for (final m in messages) {
      unique[m.id] = m;
    }
    final list = unique.values.toList();
    list.sort((a, b) {
      final at = a.sentAt;
      final bt = b.sentAt;
      if (at == null || bt == null) return 0;
      return at.compareTo(bt);
    });
    return list;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  Future<void> close() {
    _frameSub?.cancel();
    socket.disconnect();
    return super.close();
  }
}

class _ParsedPage {
  final List<ChatMessageModel> messages;
  final bool hasMore;
  _ParsedPage(this.messages, this.hasMore);
}
