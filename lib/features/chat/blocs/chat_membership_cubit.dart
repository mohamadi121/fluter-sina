import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/models/chat_participant_model.dart';
import 'package:asood/features/chat/data/models/chat_room_model.dart';

part 'chat_membership_state.dart';

class ChatMembershipCubit extends Cubit<ChatMembershipState> {
  final ChatRepository repository;

  ChatMembershipCubit({required this.repository})
    : super(const ChatMembershipState());

  Future<void> load(String roomId) async {
    emit(state.copyWith(status: ChatMembershipStatus.loading, roomId: roomId));
    final result = await repository.participants(roomId);
    if (result is! Success) {
      _failure(result);
      return;
    }
    emit(
      state.copyWith(
        status: ChatMembershipStatus.loaded,
        participants: _parseParticipants(result.response),
        busy: false,
      ),
    );
  }

  Future<bool> add({required String mobileNumber, String role = 'member'}) {
    return _mutate(
      () => repository.addParticipant(
        state.roomId,
        mobileNumber: mobileNumber,
        role: role,
      ),
    );
  }

  Future<bool> changeRole(int userId, String role) {
    return _mutate(
      () => repository.changeParticipantRole(state.roomId, userId, role),
    );
  }

  Future<bool> remove(int userId) {
    return _mutate(() => repository.removeParticipant(state.roomId, userId));
  }

  Future<bool> transfer(int userId) {
    return _mutate(() => repository.transferOwnership(state.roomId, userId));
  }

  Future<bool> leave() async {
    emit(state.copyWith(busy: true));
    final result = await repository.leaveRoom(state.roomId);
    if (result is! Success) {
      _failure(result, preserveList: true);
      return false;
    }
    emit(state.copyWith(busy: false, leftRoom: true));
    return true;
  }

  Future<ChatRoomModel?> createGroup({
    required String name,
    required int maxParticipants,
    List<String> memberMobiles = const [],
  }) async {
    emit(state.copyWith(status: ChatMembershipStatus.loading, busy: true));
    final created = await repository.createRoom({
      'name': name,
      'room_type': 'group',
      'max_participants': maxParticipants,
    });
    if (created is! Success || created.response is! Map) {
      _failure(created);
      return null;
    }
    final room = ChatRoomModel.fromJson(
      Map<String, dynamic>.from(created.response as Map),
    );
    final failedMobiles = <String>[];
    for (final mobile in memberMobiles.toSet()) {
      final result = await repository.addParticipant(
        room.id,
        mobileNumber: mobile,
      );
      if (result is! Success) failedMobiles.add(mobile);
    }
    emit(
      state.copyWith(
        status: ChatMembershipStatus.loaded,
        roomId: room.id,
        createdRoom: room,
        busy: false,
        error:
            failedMobiles.isEmpty
                ? null
                : 'گروه ساخته شد، اما افزودن ${failedMobiles.length} عضو ناموفق بود.',
      ),
    );
    return room;
  }

  Future<bool> _mutate(Future<dynamic> Function() request) async {
    emit(state.copyWith(busy: true));
    final result = await request();
    if (result is! Success) {
      _failure(result, preserveList: true);
      return false;
    }
    await load(state.roomId);
    return true;
  }

  void _failure(dynamic result, {bool preserveList = false}) {
    emit(
      state.copyWith(
        status:
            preserveList
                ? ChatMembershipStatus.loaded
                : ChatMembershipStatus.failure,
        busy: false,
        error: result is Failure ? result.message : 'خطا در مدیریت اعضای گفتگو',
      ),
    );
  }

  List<ChatParticipantModel> _parseParticipants(dynamic data) {
    final list = data is Map ? data['results'] : data;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(
          (item) =>
              ChatParticipantModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
