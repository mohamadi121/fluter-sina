import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/features/notification/blocs/notification_bloc.dart';
import 'package:asood/features/notification/data/notification_model.dart';
import 'package:asood/locator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = locator<NotificationBloc>()..add(const LoadNotifications());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colora.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('اعلان‌ها'),
          actions: [
            TextButton(
              onPressed: () => _bloc.add(const MarkAllNotificationsRead()),
              child: const Text(
                'خواندن همه',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            switch (state.status) {
              case NotificationStatus.loading:
              case NotificationStatus.initial:
                return const Center(child: CircularProgressIndicator());
              case NotificationStatus.failure:
                return Center(
                  child: Text(state.error ?? 'خطا در دریافت اعلان‌ها'),
                );
              case NotificationStatus.loaded:
                if (state.notifications.isEmpty) {
                  return const Center(child: Text('اعلانی وجود ندارد'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _bloc.add(const LoadNotifications()),
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      return _NotificationTile(
                        notification: n,
                        onTap:
                            n.isRead
                                ? null
                                : () => _bloc.add(MarkNotificationRead(n.id)),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        notification.isRead
            ? Icons.notifications_none
            : Icons.notifications_active,
        color: notification.isRead ? Colors.grey : Colora.primaryColor,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor:
          notification.isRead
              ? null
              : Colora.primaryColor.withValues(alpha: 0.05),
    );
  }
}
