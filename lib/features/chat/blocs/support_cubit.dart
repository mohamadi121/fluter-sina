import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/chat/data/support_api_service.dart';

part 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportApiService api;

  SupportCubit({required this.api}) : super(const SupportState());

  Future<void> load() async {
    emit(state.copyWith(status: SupportStatus.loading));

    final res = await api.tickets();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: SupportStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SupportStatus.loaded,
        tickets: _parse(res.response),
      ),
    );
  }

  /// Returns the new ticket's chat_room_id on success, else null.
  Future<String?> create({
    required String subject,
    required String description,
  }) async {
    emit(state.copyWith(status: SupportStatus.creating));

    final res = await api.createTicket(
      subject: subject,
      description: description,
    );
    if (res is! Success) {
      emit(
        state.copyWith(
          status: SupportStatus.failure,
          error: res is Failure ? res.message : 'ثبت تیکت ناموفق بود',
        ),
      );
      return null;
    }

    await load();
    final data = res.response;
    return data is Map ? data['chat_room_id']?.toString() : null;
  }

  List<Map<String, dynamic>> _parse(dynamic data) {
    final list = data is Map ? data['results'] : data;
    if (list is! List) {
      return const [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
