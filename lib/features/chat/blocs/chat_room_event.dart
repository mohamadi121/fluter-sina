part of 'chat_room_bloc.dart';

sealed class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoom extends ChatRoomEvent {
  final String roomId;
  const LoadRoom(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class LoadMoreMessages extends ChatRoomEvent {
  const LoadMoreMessages();
}

class SendChatMessage extends ChatRoomEvent {
  final String content;
  const SendChatMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class SetTyping extends ChatRoomEvent {
  final bool typing;
  const SetTyping(this.typing);

  @override
  List<Object?> get props => [typing];
}

/// Internal: a decoded frame arrived from the socket.
class FrameReceived extends ChatRoomEvent {
  final Map<String, dynamic> frame;
  const FrameReceived(this.frame);

  @override
  List<Object?> get props => [frame];
}
