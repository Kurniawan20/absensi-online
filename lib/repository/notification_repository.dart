import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/notification/notification_state.dart';
import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class NotificationRepository {
  final http.Client _client;
  final SecureStorage _secureStorage;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final SharedPreferences _preferences;
  static const String _prefsKey = 'notification_preferences';

  NotificationRepository({
    required SharedPreferences preferences,
    http.Client? client,
    SecureStorage? secureStorage,
    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorage(),
        _preferences = preferences,
        _flutterLocalNotificationsPlugin =
            flutterLocalNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null) {
          // Navigate to appropriate screen based on payload
        }
      },
    );
  }

  Future<Map<String, dynamic>> getNotifications({
    required int page,
    required int limit,
  }) async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.BASE_URL}/notifications?page=$page&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'notifications': (data['notifications'] as List)
              .map((notification) => NotificationItem.fromJson(notification))
              .toList(),
          'hasMore': data['hasMore'],
          'currentPage': data['currentPage'],
          'unreadCount': data['unreadCount'],
        };
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.post(
        Uri.parse('${ApiConstants.BASE_URL}/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.post(
        Uri.parse('${ApiConstants.BASE_URL}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.BASE_URL}/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.BASE_URL}/notifications/clear-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear all notifications');
      }
    } catch (e) {
      throw Exception('Error clearing all notifications: $e');
    }
  }

  Future<NotificationPreferences> getNotificationPreferences() async {
    final prefsJson = _preferences.getString(_prefsKey);
    if (prefsJson != null) {
      return NotificationPreferences.fromJson(json.decode(prefsJson));
    }
    return NotificationPreferences(
      pushEnabled: true,
      emailEnabled: true,
      attendanceAlerts: true,
      announcementAlerts: true,
      scheduleReminders: true,
    );
  }

  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      // Save locally
      await _preferences.setString(_prefsKey, json.encode(preferences.toJson()));

      // Update on server
      final token = await _secureStorage.getToken();
      final response = await _client.put(
        Uri.parse('${ApiConstants.BASE_URL}/notifications/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update notification preferences');
      }
    } catch (e) {
      throw Exception('Error updating notification preferences: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
