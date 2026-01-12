import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AttendanceReminderService {
  static final AttendanceReminderService _instance =
      AttendanceReminderService._internal();
  factory AttendanceReminderService() => _instance;
  AttendanceReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int checkOutReminderId = 1001;
  static const int lateCheckOutReminderId = 1002;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Set local timezone
    final String timeZoneName = await _getTimeZoneName();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('AttendanceReminderService initialized');
  }

  Future<String> _getTimeZoneName() async {
    try {
      // Try to get system timezone
      if (Platform.isAndroid) {
        return 'Asia/Jakarta'; // Default for Indonesia
      } else if (Platform.isIOS) {
        return 'Asia/Jakarta';
      }
    } catch (e) {
      print('Error getting timezone: $e');
    }
    return 'Asia/Jakarta'; // Fallback
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to attendance page
  }

  /// Schedule reminder for check-out (absen pulang)
  /// Call this after successful check-in (absen masuk)
  Future<void> scheduleCheckOutReminder({
    required DateTime checkInTime,
    int workHours = 8, // Default 8 jam kerja
  }) async {
    if (!_isInitialized) await initialize();

    // Cancel any existing reminders
    await cancelCheckOutReminders();

    // ⚠️ TESTING MODE: Quick reminders for testing
    // TODO: Revert to production timing before release
    // Production: 30 minutes before check-out (8 hours after check-in)
    // Testing: 2 minutes after check-in

    // Calculate check-out time (8 hours after check-in)
    final checkOutTime = checkInTime.add(Duration(hours: workHours));

    // TESTING: Schedule reminder 2 minutes after check-in (instead of 30 min before checkout)
    final reminderTime = checkInTime.add(const Duration(minutes: 2));

    // Production version (commented out for testing):
    // final reminderTime = checkOutTime.subtract(const Duration(minutes: 30));

    // Only schedule if reminder time is in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: checkOutReminderId,
        title: '⏰ Pengingat Absen Pulang',
        body:
            'Jangan lupa absen pulang! Waktu pulang Anda sekitar ${_formatTime(checkOutTime)}',
        scheduledTime: reminderTime,
        payload: 'checkout_reminder',
      );

      print(
          '✅ [TESTING] Check-out reminder scheduled for: ${_formatTime(reminderTime)} (2 min from now)');
    }

    // TESTING: Schedule late reminder 4 minutes after check-in (instead of 1 hour after checkout)
    final lateReminderTime = checkInTime.add(const Duration(minutes: 4));

    // Production version (commented out for testing):
    // final lateReminderTime = checkOutTime.add(const Duration(hours: 1));

    if (lateReminderTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: lateCheckOutReminderId,
        title: '🔔 Anda Belum Absen Pulang!',
        body: 'Segera lakukan absen pulang untuk mencatat waktu kerja Anda.',
        scheduledTime: lateReminderTime,
        payload: 'late_checkout_reminder',
      );

      print(
          '✅ [TESTING] Late check-out reminder scheduled for: ${_formatTime(lateReminderTime)} (4 min from now)');
    }

    // Save reminder status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_checkout_reminder', true);
    await prefs.setString(
        'reminder_check_in_time', checkInTime.toIso8601String());
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'attendance_reminder_channel',
      'Pengingat Absensi',
      channelDescription: 'Notifikasi pengingat untuk absen pulang',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel all check-out reminders
  /// Call this after successful check-out
  Future<void> cancelCheckOutReminders() async {
    await _notifications.cancel(checkOutReminderId);
    await _notifications.cancel(lateCheckOutReminderId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_checkout_reminder');
    await prefs.remove('reminder_check_in_time');

    print('Check-out reminders cancelled');
  }

  // Notification ID for daily reminder
  static const int dailyCheckOutReminderId = 1003;

  /// Schedule daily reminder at 17:00 (5 PM) for check-out
  /// Call this once when the user logs in or app starts
  Future<void> scheduleDailyCheckOutReminder({
    int hour = 17,
    int minute = 0,
  }) async {
    if (!_isInitialized) await initialize();

    // Cancel any existing daily reminder first
    await cancelDailyCheckOutReminder();

    // Create scheduled time for today at specified hour:minute
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime scheduledTZDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_checkout_reminder_channel',
      'Pengingat Harian Absen Pulang',
      channelDescription:
          'Notifikasi pengingat harian untuk absen pulang jam 17:00',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily repeating notification
    await _notifications.zonedSchedule(
      dailyCheckOutReminderId,
      '🏠 Waktunya Pulang!',
      'Jangan lupa absen pulang sebelum meninggalkan kantor.',
      scheduledTZDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at this time
      payload: 'daily_checkout_reminder',
    );

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_checkout_reminder_enabled', true);
    await prefs.setInt('daily_checkout_reminder_hour', hour);
    await prefs.setInt('daily_checkout_reminder_minute', minute);

    print(
        '✅ Daily check-out reminder scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} every day');
  }

  /// Cancel daily check-out reminder
  Future<void> cancelDailyCheckOutReminder() async {
    await _notifications.cancel(dailyCheckOutReminderId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_checkout_reminder_enabled');

    print('Daily check-out reminder cancelled');
  }

  /// Check if daily reminder is enabled
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_checkout_reminder_enabled') ?? false;
  }

  /// Get the scheduled time for daily reminder
  Future<String?> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_checkout_reminder_hour');
    final minute = prefs.getInt('daily_checkout_reminder_minute');
    if (hour != null && minute != null) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Schedule test reminder (for quick testing - 2 minutes from now)
  Future<void> scheduleTestReminder() async {
    if (!_isInitialized) await initialize();

    final testTime = DateTime.now().add(const Duration(minutes: 2));

    await _scheduleNotification(
      id: 9999,
      title: '🧪 Test Reminder (2 min)',
      body: 'Ini adalah test reminder yang dijadwalkan 2 menit yang lalu',
      scheduledTime: testTime,
      payload: 'test_reminder',
    );

    print('✅ Test reminder scheduled for: ${_formatTime(testTime)}');
  }

  /// Show immediate notification (for testing or immediate reminders)
  Future<void> showImmediateReminder({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'attendance_reminder_channel',
      'Pengingat Absensi',
      channelDescription: 'Notifikasi pengingat untuk absen pulang',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      title,
      body,
      details,
      payload: 'immediate_reminder',
    );
  }

  /// Check if user has pending check-out reminder
  Future<bool> hasPendingCheckOutReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_checkout_reminder') ?? false;
  }

  /// Get check-in time from saved reminder
  Future<DateTime?> getSavedCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('reminder_check_in_time');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_checkout_reminder');
    await prefs.remove('reminder_check_in_time');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Request notification permissions (especially for iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
}
