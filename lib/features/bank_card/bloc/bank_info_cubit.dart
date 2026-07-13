import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/bank_card/data/bank_api_service.dart';

part 'bank_info_state.dart';

class BankInfoCubit extends Cubit<BankInfoState> {
  final BankApiService api;

  BankInfoCubit({required this.api}) : super(const BankInfoState());

  Future<void> load() async {
    emit(state.copyWith(status: BankInfoStatus.loading, error: null));
    final results = await Future.wait([api.banks(), api.myBankInfos()]);
    final failure = results.whereType<Failure>().firstOrNull;
    if (failure != null || results.any((result) => result is! Success)) {
      emit(
        state.copyWith(
          status: BankInfoStatus.failure,
          error: failure?.message ?? 'پاسخ نامعتبر سرور',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: BankInfoStatus.loaded,
        banks: _maps((results[0] as Success).response),
        bankInfos: _maps((results[1] as Success).response),
        pendingIds: const {},
        error: null,
      ),
    );
  }

  Future<bool> save({String? id, required Map<String, dynamic> body}) async {
    if (state.status == BankInfoStatus.saving) return false;
    emit(state.copyWith(status: BankInfoStatus.saving, error: null));
    final result =
        id == null ? await api.create(body) : await api.update(id, body);
    if (result is! Success || result.response is! Map) {
      emit(
        state.copyWith(
          status: BankInfoStatus.loaded,
          error:
              result is Failure
                  ? result.message
                  : 'ذخیره اطلاعات بانکی ناموفق بود',
        ),
      );
      return false;
    }

    final saved = Map<String, dynamic>.from(result.response as Map);
    final infos = List<Map<String, dynamic>>.from(state.bankInfos);
    final index = infos.indexWhere(
      (item) => item['id'].toString() == saved['id'].toString(),
    );
    if (index == -1) {
      infos.insert(0, saved);
    } else {
      infos[index] = saved;
    }
    emit(
      state.copyWith(
        status: BankInfoStatus.loaded,
        bankInfos: infos,
        error: null,
      ),
    );
    return true;
  }

  Future<bool> delete(String id) async {
    if (state.pendingIds.contains(id)) return false;
    final pending = Set<String>.from(state.pendingIds)..add(id);
    emit(state.copyWith(pendingIds: pending, error: null));

    final result = await api.delete(id);
    final settled = Set<String>.from(state.pendingIds)..remove(id);
    if (result is! Success) {
      emit(
        state.copyWith(
          pendingIds: settled,
          error:
              result is Failure
                  ? result.message
                  : 'حذف اطلاعات بانکی ناموفق بود',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        bankInfos:
            state.bankInfos
                .where((item) => item['id'].toString() != id)
                .toList(),
        pendingIds: settled,
        error: null,
      ),
    );
    return true;
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
