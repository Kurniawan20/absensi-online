import 'dart:async';

/// Global notification refresh callback
/// Used to trigger notification list refresh when push notification is received
class NotificationRefreshService {
  static final NotificationRefreshService _instance = NotificationRefreshService._internal();
  factory NotificationRefreshService() => _instance;
  NotificationRefreshService._internal();

  final _refreshController = StreamController<void>.broadcast();

  /// Stream that emits when notifications should be refreshed
  Stream<void> get onRefresh => _refreshController.stream;

  /// Trigger a notification refresh
  void triggerRefresh() {
    print('NotificationRefreshService: Triggering refresh');
    _refreshController.add(null);
  }

  void dispose() {
    _refreshController.close();
  }
}
