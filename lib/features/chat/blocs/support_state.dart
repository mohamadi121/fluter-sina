part of 'support_cubit.dart';

enum SupportStatus { initial, loading, loaded, creating, failure }

class SupportState extends Equatable {
  final SupportStatus status;
  final List<Map<String, dynamic>> tickets;
  final String? error;

  const SupportState({
    this.status = SupportStatus.initial,
    this.tickets = const [],
    this.error,
  });

  SupportState copyWith({
    SupportStatus? status,
    List<Map<String, dynamic>>? tickets,
    String? error,
  }) {
    return SupportState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, tickets, error];
}
