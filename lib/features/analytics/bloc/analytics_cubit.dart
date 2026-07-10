import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/analytics/data/analytics_api_service.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  final AnalyticsApiService api;

  AnalyticsCubit({required this.api}) : super(const AnalyticsState());

  Future<void> load() async {
    emit(state.copyWith(status: AnalyticsStatus.loading));

    final res = await api.dashboard();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AnalyticsStatus.loaded,
        data:
            res.response is Map
                ? Map<String, dynamic>.from(res.response as Map)
                : const {},
      ),
    );
  }
}
