part of 'chat_list_cubit.dart';

enum ChatListStatus { initial, loading, loaded, failure }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatRoomModel> rooms;
  final String? error;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.rooms = const [],
    this.error,
  });

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoomModel>? rooms,
    String? error,
  }) {
    return ChatListState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, rooms, error];
}
