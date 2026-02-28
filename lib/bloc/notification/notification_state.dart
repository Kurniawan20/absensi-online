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
  final int id;
  final String npp;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.npp,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.data,
  });

  /// Getter for backward compatibility (message -> body)
  String get message => body;

  /// Getter for backward compatibility (timestamp -> createdAt)
  DateTime get timestamp => createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // Parse data field - can be Map, List, or null
    Map<String, dynamic>? dataField;
    if (json['data'] is Map<String, dynamic>) {
      dataField = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is Map) {
      dataField = Map<String, dynamic>.from(json['data'] as Map);
    }
    // If it's a List or other type, leave it as null

    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      npp: json['npp']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['isRead'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: _parseDateTime(json['created_at']) ?? _parseDateTime(json['timestamp']) ?? DateTime.now(),
      data: dataField,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'npp': npp,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }

  NotificationItem copyWith({
    int? id,
    String? npp,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      npp: npp ?? this.npp,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
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
