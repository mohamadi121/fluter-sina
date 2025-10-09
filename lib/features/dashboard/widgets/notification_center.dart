import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Notification Center Widget
class NotificationCenter extends StatefulWidget {
  final List<NotificationItem> notifications;
  final Function(String) onNotificationDismiss;
  final Function(String) onNotificationTap;
  final VoidCallback onClearAll;

  const NotificationCenter({
    super.key,
    required this.notifications,
    required this.onNotificationDismiss,
    required this.onNotificationTap,
    required this.onClearAll,
  });

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (widget.notifications.isEmpty)
              _buildEmptyState()
            else
              _buildNotificationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Notifications',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.notifications.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.notifications.length}',
                  style: AppTheme.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.notifications.isNotEmpty)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onClearAll();
            },
            child: Text(
              'Clear All',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: AppTheme.titleMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return SlideTransition(
          position: _slideAnimation,
          child: NotificationCard(
            notification: widget.notifications[index],
            onDismiss: () => widget.onNotificationDismiss(
              widget.notifications[index].id,
            ),
            onTap: () => widget.onNotificationTap(
              widget.notifications[index].id,
            ),
          ),
        );
      },
    );
  }
}

/// Individual Notification Card
class NotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _dismissController;
  late Animation<double> _dismissAnimation;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _dismissAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dismissAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _dismissAnimation.value,
          child: Opacity(
            opacity: _dismissAnimation.value,
            child: Dismissible(
              key: Key(widget.notification.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                HapticFeedback.mediumImpact();
                widget.onDismiss();
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.notification.isRead 
                        ? Colors.grey[50]
                        : _getNotificationColor().withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.notification.isRead
                          ? Colors.grey[300]!
                          : _getNotificationColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContent(),
                      ),
                      _buildTimestamp(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getNotificationColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNotificationIcon(),
        color: _getNotificationColor(),
        size: 20,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.notification.title,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: widget.notification.isRead 
                ? FontWeight.normal 
                : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.notification.message,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.notification.actionLabel != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              widget.notification.actionLabel!,
              style: AppTheme.labelSmall.copyWith(
                color: _getNotificationColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimestamp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTimestamp(widget.notification.timestamp),
          style: AppTheme.labelSmall.copyWith(
            color: Colors.grey[500],
          ),
        ),
        if (!widget.notification.isRead)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getNotificationColor(),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case NotificationType.security:
        return Icons.security;
      case NotificationType.device:
        return Icons.devices;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.energy:
        return Icons.battery_alert;
      case NotificationType.automation:
        return Icons.auto_awesome;
      case NotificationType.update:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor() {
    switch (widget.notification.type) {
      case NotificationType.security:
        return Colors.red;
      case NotificationType.device:
        return Colors.blue;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.energy:
        return Colors.green;
      case NotificationType.automation:
        return Colors.purple;
      case NotificationType.update:
        return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

/// Notification Item Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
  });
}

/// Notification Types
enum NotificationType {
  security,
  device,
  system,
  energy,
  automation,
  update,
}