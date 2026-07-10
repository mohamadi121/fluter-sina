part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, loaded, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final String? error;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    String? error,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, notifications, error];
}
