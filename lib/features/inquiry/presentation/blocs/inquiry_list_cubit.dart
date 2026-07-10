import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/inquiry/domain/inquiry_repository.dart';

part 'inquiry_list_state.dart';

/// Owner's price-inquiry list + the send/delete actions on each item.
class InquiryListCubit extends Cubit<InquiryListState> {
  final InquiryRepo repo;

  InquiryListCubit({required this.repo}) : super(const InquiryListState());

  Future<void> load() async {
    emit(state.copyWith(status: InquiryListStatus.loading));

    final res = await repo.list();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: InquiryListStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    emit(
      state.copyWith(
        status: InquiryListStatus.loaded,
        inquiries:
            data is List
                ? data
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : const [],
      ),
    );
  }

  /// Returns true if the send succeeded.
  Future<bool> send(String id) async {
    final res = await repo.sendInquiry(id);
    if (res is! Success) {
      emit(
        state.copyWith(
          error: res is Failure ? res.message : 'ارسال ناموفق بود',
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> delete(String id) async {
    final res = await repo.deleteInquiry(id);
    if (res is Success) {
      emit(
        state.copyWith(
          inquiries:
              state.inquiries.where((i) => i['id'].toString() != id).toList(),
        ),
      );
    } else {
      emit(
        state.copyWith(error: res is Failure ? res.message : 'حذف ناموفق بود'),
      );
    }
  }
}
