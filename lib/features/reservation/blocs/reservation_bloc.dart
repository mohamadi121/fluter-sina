import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/reservation/data/reservation_api_service.dart';

part 'reservation_event.dart';
part 'reservation_state.dart';

/// User booking flow: services for a market -> reserve-times for a service ->
/// create reservation. Also lists the user's own reservations.
class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationApiService api;

  ReservationBloc({required this.api}) : super(const ReservationState()) {
    on<LoadServices>(_onLoadServices);
    on<LoadReserveTimes>(_onLoadReserveTimes);
    on<CreateReservation>(_onCreate);
    on<LoadMyReservations>(_onLoadMine);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ReservationState> emit,
  ) async {
    emit(state.copyWith(status: ReservationStatus.loading));
    final res = await api.services(event.marketId);
    if (res is! Success) {
      emit(_fail(res));
      return;
    }
    emit(
      state.copyWith(
        status: ReservationStatus.loaded,
        services: _asList(res.response),
        reserveTimes: const [],
      ),
    );
  }

  Future<void> _onLoadReserveTimes(
    LoadReserveTimes event,
    Emitter<ReservationState> emit,
  ) async {
    emit(state.copyWith(status: ReservationStatus.loading));
    final res = await api.reserveTimes(event.serviceId);
    if (res is! Success) {
      emit(_fail(res));
      return;
    }
    emit(
      state.copyWith(
        status: ReservationStatus.loaded,
        reserveTimes: _asList(res.response),
      ),
    );
  }

  Future<void> _onCreate(
    CreateReservation event,
    Emitter<ReservationState> emit,
  ) async {
    emit(state.copyWith(status: ReservationStatus.booking));
    final res = await api.createReservation(
      reserveTimeId: event.reserveTimeId,
      specialistId: event.specialistId,
    );
    if (res is Success) {
      emit(state.copyWith(status: ReservationStatus.booked));
    } else {
      emit(_fail(res));
    }
  }

  Future<void> _onLoadMine(
    LoadMyReservations event,
    Emitter<ReservationState> emit,
  ) async {
    emit(state.copyWith(status: ReservationStatus.loading));
    final res = await api.myReservations();
    if (res is! Success) {
      emit(_fail(res));
      return;
    }
    emit(
      state.copyWith(
        status: ReservationStatus.loaded,
        myReservations: _asList(res.response),
      ),
    );
  }

  ReservationState _fail(dynamic res) => state.copyWith(
    status: ReservationStatus.failure,
    error: res is Failure ? res.message : 'خطای نامشخص',
  );

  List<Map<String, dynamic>> _asList(dynamic data) {
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
