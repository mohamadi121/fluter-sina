import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/data/chat_repository.dart';
import 'package:asood/features/chat/data/models/chat_room_model.dart';

part 'chat_list_state.dart';

class ChatListCubit extends Cubit<ChatListState> {
  final ChatRepository repository;

  ChatListCubit({required this.repository}) : super(const ChatListState());

  Future<void> load() async {
    emit(state.copyWith(status: ChatListStatus.loading));

    final res = await repository.rooms();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: ChatListStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ChatListStatus.loaded,
        rooms: _parseRooms(res.response),
      ),
    );
  }

  List<ChatRoomModel> _parseRooms(dynamic data) {
    // DRF viewset list may be a bare list or a paginated {results:[...]}.
    final list = data is Map ? data['results'] : data;
    if (list is! List) {
      return const [];
    }
    return list
        .whereType<Map>()
        .map((e) => ChatRoomModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
