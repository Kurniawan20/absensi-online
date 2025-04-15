import 'package:flutter/material.dart';
import '../bloc/notification/notification_state.dart';
import 'package:intl/intl.dart';

class NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  final ScrollController scrollController;
  final Function(NotificationItem) onNotificationTap;
  final Function(NotificationItem) onNotificationDismiss;

  const NotificationList({
    Key? key,
    required this.notifications,
    required this.scrollController,
    required this.onNotificationTap,
    required this.onNotificationDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final bool showDate = index == 0 ||
            !_isSameDay(
              notifications[index].timestamp,
              notifications[index - 1].timestamp,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) _buildDateHeader(notification.timestamp, context),
            Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) => onNotificationDismiss(notification),
              child: _buildNotificationTile(notification, context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime timestamp, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        _getDateHeader(timestamp),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, BuildContext context) {
    return InkWell(
      onTap: () => onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm').format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'attendance':
        iconData = Icons.access_time;
        iconColor = Colors.blue;
        break;
      case 'announcement':
        iconData = Icons.campaign;
        iconColor = Colors.orange;
        break;
      case 'schedule':
        iconData = Icons.event;
        iconColor = Colors.green;
        break;
      case 'alert':
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final timestampDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (timestampDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (timestampDate == yesterday) {
      return 'Yesterday';
    } else if (timestamp.year == now.year) {
      return DateFormat('MMMM d').format(timestamp);
    }
    return DateFormat('MMMM d, y').format(timestamp);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
