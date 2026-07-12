part of 'reservation_bloc.dart';

enum ReservationStatus { initial, loading, loaded, booking, booked, failure }

class ReservationState extends Equatable {
  final ReservationStatus status;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> specialists;
  final List<Map<String, dynamic>> reserveTimes;
  final List<Map<String, dynamic>> myReservations;
  final String? error;

  const ReservationState({
    this.status = ReservationStatus.initial,
    this.services = const [],
    this.specialists = const [],
    this.reserveTimes = const [],
    this.myReservations = const [],
    this.error,
  });

  ReservationState copyWith({
    ReservationStatus? status,
    List<Map<String, dynamic>>? services,
    List<Map<String, dynamic>>? specialists,
    List<Map<String, dynamic>>? reserveTimes,
    List<Map<String, dynamic>>? myReservations,
    String? error,
  }) {
    return ReservationState(
      status: status ?? this.status,
      services: services ?? this.services,
      specialists: specialists ?? this.specialists,
      reserveTimes: reserveTimes ?? this.reserveTimes,
      myReservations: myReservations ?? this.myReservations,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    services,
    specialists,
    reserveTimes,
    myReservations,
    error,
  ];
}
