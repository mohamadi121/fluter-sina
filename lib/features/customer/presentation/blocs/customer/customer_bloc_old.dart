// ignore_for_file: unnecessary_type_check

import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/models/market_model.dart';
import 'package:asoud/features/customer/data/model/customer_request_model.dart';
import 'package:bloc/bloc.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc() : super(CustomerState.initial()) {
    on<GetCusomerRequest>(_onGetCusomerRequest);
    on<GetCusomerOrders>(_onGetCusomerOrders);
    on<GetCusomerStors>(_onGetCusomerStors);
    on<TrackPayment>(_onTrackPayment);
    on<AcceptPayment>(_onAcceptPayment);
  }

  void _onGetCusomerRequest(
    GetCusomerRequest event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = Success(true); // TODO: Implement customer adding
      if (res is Success) {
        emit(state.copyWith(status: const UiSuccess()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  void _onGetCusomerOrders(
    GetCusomerOrders event,
    Emitter<CustomerState> emit,
  ) {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = Success();
      if (res is Success) {
        emit(state.copyWith(status: const UiSuccess()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  void _onGetCusomerStors(GetCusomerStors event, Emitter<CustomerState> emit) {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = Success();
      if (res is Success) {
        emit(state.copyWith(status: const UiSuccess()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  void _onTrackPayment(TrackPayment event, Emitter<CustomerState> emit) {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = Success();
      if (res is Success) {
        emit(state.copyWith(status: const UiSuccess()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }

  void _onAcceptPayment(AcceptPayment event, Emitter<CustomerState> emit) {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final res = Success();
      if (res is Success) {
        emit(state.copyWith(status: const UiSuccess()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    }
  }
}
