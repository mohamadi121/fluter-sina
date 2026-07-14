part of 'chat_membership_cubit.dart';

enum ChatMembershipStatus { initial, loading, loaded, failure }

class ChatMembershipState extends Equatable {
  final ChatMembershipStatus status;
  final String roomId;
  final List<ChatParticipantModel> participants;
  final bool busy;
  final bool leftRoom;
  final ChatRoomModel? createdRoom;
  final String? error;

  const ChatMembershipState({
    this.status = ChatMembershipStatus.initial,
    this.roomId = '',
    this.participants = const [],
    this.busy = false,
    this.leftRoom = false,
    this.createdRoom,
    this.error,
  });

  ChatMembershipState copyWith({
    ChatMembershipStatus? status,
    String? roomId,
    List<ChatParticipantModel>? participants,
    bool? busy,
    bool? leftRoom,
    ChatRoomModel? createdRoom,
    String? error,
  }) {
    return ChatMembershipState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      participants: participants ?? this.participants,
      busy: busy ?? this.busy,
      leftRoom: leftRoom ?? this.leftRoom,
      createdRoom: createdRoom ?? this.createdRoom,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    roomId,
    participants,
    busy,
    leftRoom,
    createdRoom,
    error,
  ];
}
