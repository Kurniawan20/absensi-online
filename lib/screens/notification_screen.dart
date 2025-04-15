import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../widgets/notification_list.dart';
import '../widgets/notification_preferences_sheet.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final state = context.read<NotificationBloc>().state;
        if (state is NotificationsLoadSuccess && state.hasMore) {
          context.read<NotificationBloc>().add(
                LoadNotifications(
                  page: state.currentPage + 1,
                ),
              );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showPreferences(context),
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoadSuccess &&
                  state.unreadCount > 0) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      context
                          .read<NotificationBloc>()
                          .add(MarkAllNotificationsAsRead());
                    } else if (value == 'clear_all') {
                      _showClearConfirmation(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark all as read'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear all'),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<NotificationBloc>().add(RefreshNotifications());
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<NotificationBloc>()
                            .add(RefreshNotifications());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoadSuccess) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  if (state.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mark_email_unread, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${state.unreadCount} unread notification${state.unreadCount == 1 ? '' : 's'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: NotificationList(
                      notifications: state.notifications,
                      scrollController: _scrollController,
                      onNotificationTap: _handleNotificationTap,
                      onNotificationDismiss: _handleNotificationDismiss,
                    ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const NotificationPreferencesSheet(),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CLEAR'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (mounted) {
        context.read<NotificationBloc>().add(ClearAllNotifications());
      }
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      context
          .read<NotificationBloc>()
          .add(MarkNotificationAsRead(notification.id));
    }
    // Handle navigation based on notification type
    if (notification.data != null) {
      // Navigate to appropriate screen based on notification data
    }
  }

  void _handleNotificationDismiss(NotificationItem notification) {
    context.read<NotificationBloc>().add(DeleteNotification(notification.id));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
