import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future _notificationDetails() async {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'channel name',
        // 'channel description',
          channelDescription: '',
          importance: Importance.max
      ),
      iOS: IOSNotificationDetails(),
    );
  }

  static Future init({bool initScheduled = false}) async {
    final android = AndroidInitializationSettings('@drawable/ic_stat_account_tree');
    final iOS = IOSInitializationSettings();
    final settings = InitializationSettings(android: android,iOS: iOS);

    await _notifications.initialize(
        settings,
        onSelectNotification:(payload) async {
          onNotifications.add(payload);
        }
    );
  }

  static Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload
  }) async =>
      _notifications.show(
          id,
          title,
          body,
          await _notificationDetails(),
          payload: payload,
      );

  static void showScheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduleDate,
  }) async =>
      _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduleDate,tz.local),
        await _notificationDetails(),
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
}