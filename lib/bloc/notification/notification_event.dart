import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeNotifications extends NotificationEvent {}

/// Load notifications with npp required
class LoadNotifications extends NotificationEvent {
  final String npp;
  final bool? isRead;
  final String? type;
  final int perPage;

  LoadNotifications({
    required this.npp,
    this.isRead,
    this.type,
    this.perPage = 20,
  });

  @override
  List<Object?> get props => [npp, isRead, type, perPage];
}

/// Get unread count
class GetUnreadCount extends NotificationEvent {
  final String npp;

  GetUnreadCount({required this.npp});

  @override
  List<Object?> get props => [npp];
}

/// Mark single notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final int notificationId;

  MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  final String npp;

  MarkAllNotificationsAsRead({required this.npp});

  @override
  List<Object?> get props => [npp];
}

/// Delete notification
class DeleteNotification extends NotificationEvent {
  final int notificationId;

  DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

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

/// Refresh notifications
class RefreshNotifications extends NotificationEvent {
  final String npp;

  RefreshNotifications({required this.npp});

  @override
  List<Object?> get props => [npp];
}

class HandlePushNotification extends NotificationEvent {
  final Map<String, dynamic> payload;

  HandlePushNotification(this.payload);

  @override
  List<Object?> get props => [payload];
}

/// Register FCM token after login
class RegisterFcmToken extends NotificationEvent {
  final String npp;
  final String fcmToken;
  final String? deviceId;

  RegisterFcmToken({
    required this.npp,
    required this.fcmToken,
    this.deviceId,
  });

  @override
  List<Object?> get props => [npp, fcmToken, deviceId];
}

/// Unregister FCM token on logout
class UnregisterFcmToken extends NotificationEvent {
  final String fcmToken;

  UnregisterFcmToken({required this.fcmToken});

  @override
  List<Object?> get props => [fcmToken];
}
