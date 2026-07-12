part of 'reservation_bloc.dart';

sealed class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends ReservationEvent {
  final String marketId;
  const LoadServices(this.marketId);

  @override
  List<Object?> get props => [marketId];
}

class LoadReserveTimes extends ReservationEvent {
  final String serviceId;
  const LoadReserveTimes(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class LoadSpecialists extends ReservationEvent {
  final String serviceId;
  const LoadSpecialists(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class CreateReservation extends ReservationEvent {
  final String reserveTimeId;
  final String specialistId;
  const CreateReservation({
    required this.reserveTimeId,
    required this.specialistId,
  });

  @override
  List<Object?> get props => [reserveTimeId, specialistId];
}

class LoadMyReservations extends ReservationEvent {
  const LoadMyReservations();
}
