import 'package:asood/core/http_client/api_status.dart';
import 'package:bloc/bloc.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

part 'business_event.dart';
part 'business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  BusinessBloc() : super(BusinessState.initial()) {
    on<DetermineCurrentPosition>(_onDetermineCurrentPosition);
    on<UpdateSelectedLocation>(_onUpdateSelectedLocation);
  }

  // A function that handles determining the current position. It takes in an event of type DetermineCurrentPosition
  // and an Emitter of type LocationState as parameters. It updates the state to loading, tries to get the current
  // position using Geolocator, and updates the state with the location and status loaded if successful. If there's an
  // error, it updates the state with status error and the error message.
  Future<void> _onDetermineCurrentPosition(
    DetermineCurrentPosition event,
    Emitter<BusinessState> emit,
  ) async {
    emit(state.copyWith(status: CWSStatus.loading));
    try {
      Position position = await Geolocator.getCurrentPosition();
      emit(
        state.copyWith(
          location: LatLng(position.latitude, position.longitude),
          status: CWSStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: CWSStatus.failure, message: e.toString()));
    }
  }

  void _onUpdateSelectedLocation(
    UpdateSelectedLocation event,
    Emitter<BusinessState> emit,
  ) {
    emit(
      state.copyWith(
        status: CWSStatus.success,
        location: event.location,
        isSelected: true,
      ),
    );
  }
}
