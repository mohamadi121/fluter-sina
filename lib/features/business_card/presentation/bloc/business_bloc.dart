import 'package:asoud/core/ui/ui_status.dart';
import 'package:bloc/bloc.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

part 'business_event.dart';
part 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  BusinessBloc() : super(BusinessState.initial()) {
    on<DetermineCurrentPosition>(_onDetermineCurrentPosition);
    on<UpdateSelectedLocation>(_onUpdateSelectedLocation);
    on<SaveLocation>(_onSaveLocation);
    on<ReadSavedLocation>(_onReadSavedLocation);
  }

  Future<void> _onDetermineCurrentPosition(
    DetermineCurrentPosition event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      final position = await Geolocator.getCurrentPosition();
      emit(
        state.copyWith(
          location: LatLng(position.latitude, position.longitude),
          status: const UiSuccess(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString()), message: e.toString()));
    }
  }

  void _onUpdateSelectedLocation(
    UpdateSelectedLocation event,
    Emitter<BusinessState> emit,
  ) {
    emit(
      state.copyWith(
        status: const UiSuccess(),
        location: event.location,
        isSelected: true,
      ),
    );
  }

  Future<void> _onSaveLocation(
    SaveLocation event,
    Emitter<BusinessState> emit,
  ) async {
    if (state.status is UiSuccess) {
      final current = state;
      emit(
        state.copyWith(
          status: const UiLoading(),
          location: current.location,
          isSelected: true,
        ),
      );
      // simulate save then mark success
      emit(state.copyWith(status: const UiSuccess()));
    }
  }

  Future<void> _onReadSavedLocation(
    ReadSavedLocation event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      // final a = GetStorage('agahi').read("location");
      if (true) {
        const lat = 0.0;
        const lang = 0.0;
        emit(
          state.copyWith(
            location: const LatLng(lat, lang),
            isSelected: true,
            status: const UiSuccess(),
          ),
        );
      } else {
        emit(state.copyWith(status: const UiIdle()));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString()), message: e.toString()));
    }
  }
}
