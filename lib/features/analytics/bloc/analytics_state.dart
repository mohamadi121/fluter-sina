part of 'analytics_cubit.dart';

enum AnalyticsStatus { initial, loading, loaded, failure }

class AnalyticsState extends Equatable {
  final AnalyticsStatus status;
  final Map<String, dynamic> data;
  final String? error;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.data = const {},
    this.error,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
