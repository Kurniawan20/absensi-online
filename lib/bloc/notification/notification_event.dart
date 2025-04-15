import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeNotifications extends NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final int page;
  final int limit;

  LoadNotifications({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ClearAllNotifications extends NotificationEvent {}

class UpdateNotificationPreferences extends NotificationEvent {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool attendanceAlerts;
  final bool announcementAlerts;
  final bool scheduleReminders;

  UpdateNotificationPreferences({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.attendanceAlerts,
    required this.announcementAlerts,
    required this.scheduleReminders,
  });

  @override
  List<Object?> get props => [
        pushEnabled,
        emailEnabled,
        attendanceAlerts,
        announcementAlerts,
        scheduleReminders,
      ];
}

class RefreshNotifications extends NotificationEvent {}

class HandlePushNotification extends NotificationEvent {
  final Map<String, dynamic> payload;

  HandlePushNotification(this.payload);

  @override
  List<Object?> get props => [payload];
}
