import 'dart:convert';
import 'dart:io';
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
        _flutterLocalNotificationsPlugin = flutterLocalNotificationsPlugin ??
            FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

  /// Get notifications list
  /// API: GET /api/notifications?npp={npp}&is_read={is_read}&type={type}&per_page={per_page}
  Future<Map<String, dynamic>> getNotifications({
    required String npp,
    bool? isRead,
    String? type,
    int perPage = 20,
  }) async {
    try {
      final token = await _secureStorage.getToken();

      // Build query parameters
      final queryParams = <String, String>{
        'npp': npp,
        'per_page': perPage.toString(),
      };
      if (isRead != null) {
        queryParams['is_read'] = isRead.toString();
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse(ApiConstants.notifications)
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rcode'] == '00') {
          final paginatedData = data['data'];
          final notifications = (paginatedData['data'] as List)
              .map((notification) => NotificationItem.fromJson(notification))
              .toList();

          // Parse values safely - API may return strings or ints
          final currentPage = _parseToInt(paginatedData['current_page']) ?? 1;
          final total = _parseToInt(paginatedData['total']) ?? 0;
          final perPageValue =
              _parseToInt(paginatedData['per_page']) ?? perPage;
          final lastPage = _parseToInt(paginatedData['last_page']) ?? 1;

          return {
            'notifications': notifications,
            'currentPage': currentPage,
            'total': total,
            'perPage': perPageValue,
            'hasMore': currentPage < lastPage,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to load notifications');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Helper to safely parse int from dynamic value
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Get unread count
  /// API: GET /api/notifications/unread-count?npp={npp}
  Future<int> getUnreadCount({required String npp}) async {
    try {
      final token = await _secureStorage.getToken();

      final uri = Uri.parse(ApiConstants.notificationsUnreadCount)
          .replace(queryParameters: {'npp': npp});

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rcode'] == '00') {
          return _parseToInt(data['unread_count']) ?? 0;
        } else {
          throw Exception(data['message'] ?? 'Failed to get unread count');
        }
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  /// Mark single notification as read
  /// API: POST /api/notifications/{id}/read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.post(
        Uri.parse('${ApiConstants.notifications}/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] != '00') {
          throw Exception(
              data['message'] ?? 'Failed to mark notification as read');
        }
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  /// API: POST /api/notifications/read-all
  Future<int> markAllNotificationsAsRead({required String npp}) async {
    try {
      final token = await _secureStorage.getToken();
      final response = await _client.post(
        Uri.parse(ApiConstants.notificationsReadAll),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'npp': npp}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] == '00') {
          return _parseToInt(data['updated_count']) ?? 0;
        } else {
          throw Exception(
              data['message'] ?? 'Failed to mark all notifications as read');
        }
      } else {
        throw Exception(
            'Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  /// API: DELETE /api/notifications/{id}
  Future<void> deleteNotification(int notificationId) async {
    try {
      final token = await _secureStorage.getToken();

      final response = await _client.delete(
        Uri.parse('${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] != '00') {
          throw Exception(data['message'] ?? 'Failed to delete notification');
        }
      } else {
        throw Exception(
            'Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  /// Register FCM token
  /// API: POST /api/fcm/register
  Future<void> registerFcmToken({
    required String npp,
    required String fcmToken,
    String? deviceId,
  }) async {
    try {
      final token = await _secureStorage.getToken();
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      print('=== FCM Token Registration API Call ===');
      print('URL: ${ApiConstants.fcmRegister}');
      print('NPP: $npp');
      print('FCM Token: ${fcmToken.substring(0, 20)}...');
      print('Device Type: $deviceType');
      print('Device ID: $deviceId');
      print('Auth Token present: ${token != null}');

      final response = await _client.post(
        Uri.parse(ApiConstants.fcmRegister),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'npp': npp,
          'fcm_token': fcmToken,
          'device_type': deviceType,
          if (deviceId != null) 'device_id': deviceId,
        }),
      );

      print('FCM Register Response Status: ${response.statusCode}');
      print('FCM Register Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] == '00') {
          print('FCM Token registered successfully!');
        } else {
          print('FCM Token registration failed: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to register FCM token');
        }
      } else {
        print(
            'FCM Token registration failed with status: ${response.statusCode}');
        throw Exception('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM Token registration error: $e');
      throw Exception('Error registering FCM token: $e');
    }
  }

  /// Unregister FCM token (on logout)
  /// API: POST /api/fcm/unregister
  Future<void> unregisterFcmToken({required String fcmToken}) async {
    try {
      final token = await _secureStorage.getToken();

      final response = await _client.post(
        Uri.parse(ApiConstants.fcmUnregister),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rcode'] != '00') {
          throw Exception(data['message'] ?? 'Failed to unregister FCM token');
        }
      } else {
        throw Exception(
            'Failed to unregister FCM token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unregistering FCM token: $e');
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
      await _preferences.setString(
          _prefsKey, json.encode(preferences.toJson()));

      // Update on server (optional, might not be implemented on backend yet)
      // Commenting out for now since API doesn't have this endpoint documented
      /*
      final token = await _secureStorage.getToken();
      final response = await _client.put(
        Uri.parse(ApiConstants.notificationsPreferences),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update notification preferences');
      }
      */
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
