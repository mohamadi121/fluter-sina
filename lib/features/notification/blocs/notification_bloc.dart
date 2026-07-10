import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/notification/data/notification_api_service.dart';
import 'package:asood/features/notification/data/notification_model.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationApiService api;

  NotificationBloc({required this.api}) : super(const NotificationState()) {
    on<LoadNotifications>(_onLoad);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final res = await api.list();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    final list = data is Map ? data['results'] : data;
    final notifications =
        list is List
            ? list
                .whereType<Map>()
                .map(
                  (e) =>
                      NotificationModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
            : <NotificationModel>[];

    emit(
      state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
      ),
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic: flip locally, revert on failure.
    emit(state.copyWith(notifications: _mark(event.id, true)));

    final res = await api.markAsRead(event.id);
    if (res is! Success) {
      emit(state.copyWith(notifications: _mark(event.id, false)));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final res = await api.markAllAsRead();
    if (res is Success) {
      emit(
        state.copyWith(
          notifications:
              state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        ),
      );
    }
  }

  List<NotificationModel> _mark(String id, bool read) {
    return state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: read) : n)
        .toList();
  }
}
