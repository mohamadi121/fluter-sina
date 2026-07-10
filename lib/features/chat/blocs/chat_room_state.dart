part of 'chat_room_bloc.dart';

enum ChatRoomStatus { initial, loading, ready, failure }

enum ChatConnection { offline, connecting, live }

class ChatRoomState extends Equatable {
  final ChatRoomStatus status;
  final ChatConnection connection;
  final String roomId;
  final List<ChatMessageModel> messages;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool sending;
  final bool otherTyping;
  final int? currentUserId;
  final String? error;

  const ChatRoomState({
    this.status = ChatRoomStatus.initial,
    this.connection = ChatConnection.offline,
    this.roomId = '',
    this.messages = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.sending = false,
    this.otherTyping = false,
    this.currentUserId,
    this.error,
  });

  ChatRoomState copyWith({
    ChatRoomStatus? status,
    ChatConnection? connection,
    String? roomId,
    List<ChatMessageModel>? messages,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? sending,
    bool? otherTyping,
    int? currentUserId,
    String? error,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      connection: connection ?? this.connection,
      roomId: roomId ?? this.roomId,
      messages: messages ?? this.messages,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      sending: sending ?? this.sending,
      otherTyping: otherTyping ?? this.otherTyping,
      currentUserId: currentUserId ?? this.currentUserId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    connection,
    roomId,
    messages,
    page,
    hasMore,
    loadingMore,
    sending,
    otherTyping,
    currentUserId,
    error,
  ];
}
