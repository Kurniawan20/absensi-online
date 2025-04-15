import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationError extends NotificationState {
  final String message;

  NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationsLoadSuccess extends NotificationState {
  final List<NotificationItem> notifications;
  final NotificationPreferences preferences;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;

  NotificationsLoadSuccess({
    required this.notifications,
    required this.preferences,
    required this.unreadCount,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [
        notifications,
        preferences,
        unreadCount,
        hasMore,
        currentPage,
      ];

  NotificationsLoadSuccess copyWith({
    List<NotificationItem>? notifications,
    NotificationPreferences? preferences,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationsLoadSuccess(
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class NotificationPreferencesUpdated extends NotificationState {
  final NotificationPreferences preferences;

  NotificationPreferencesUpdated(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}

class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool attendanceAlerts;
  final bool announcementAlerts;
  final bool scheduleReminders;

  NotificationPreferences({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.attendanceAlerts,
    required this.announcementAlerts,
    required this.scheduleReminders,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      attendanceAlerts: json['attendanceAlerts'] ?? true,
      announcementAlerts: json['announcementAlerts'] ?? true,
      scheduleReminders: json['scheduleReminders'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'attendanceAlerts': attendanceAlerts,
      'announcementAlerts': announcementAlerts,
      'scheduleReminders': scheduleReminders,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? attendanceAlerts,
    bool? announcementAlerts,
    bool? scheduleReminders,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      scheduleReminders: scheduleReminders ?? this.scheduleReminders,
    );
  }
}
