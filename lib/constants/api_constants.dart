class ApiConstants {
  // Base URL untuk API endpoints
  static const String baseUrl = "https://abs.basitd.net/api-absensi-mobile-v3/public/api";
  // static const String baseUrl = "http://192.168.100.182/api";
  // static const String baseUrl = "http://10.0.2.2:8081/api";
  // static const String baseUrl = "https://0800-36-71-140-31.ngrok-free.app/api";

  // App Version endpoints
  static const String appVersionCheck = '$baseUrl/app-version/check';
  static const String appVersionLatest = '$baseUrl/app-version/latest';

  // Auth endpoints
  static const String login = '$baseUrl/login';
  static const String kantor = '$baseUrl/kantor';

  // Profile endpoints
  static const String profile = '$baseUrl/profile';

  // Attendance endpoints
  static const String attendanceCheckIn = '$baseUrl/absenmasuk';
  static const String attendanceCheckOut = '$baseUrl/absenpulang';
  static const String attendanceHistory = '$baseUrl/getabsen';
  static const String attendanceStatus = '$baseUrl/absen/status';
  static const String generateReport = '$baseUrl/generatereport';

  // Working Hours endpoints
  static const String workingHoursActive = '$baseUrl/jam-absensi/active';
  static const String workingHoursList = '$baseUrl/jam-absensi';

  // Device Reset endpoints
  static const String deviceResetRequest = '$baseUrl/device-reset/request';
  static const String deviceResetStatus = '$baseUrl/device-reset/my-request';

  // Blog endpoints
  static const String blogsPublished = '$baseUrl/blogs/published';
  static const String blogsFeatured = '$baseUrl/blogs/featured';
  static const String blogsDetail = '$baseUrl/blogs'; // append /{id}
  static const String blogsBySlug = '$baseUrl/blogs/slug'; // append /{slug}
  @Deprecated('Gunakan blogsPublished atau blogsDetail sebagai pengganti.')
  static const String blogsLegacy = '$baseUrl/getblog'; // append /{npp}

  // Announcement endpoints
  static const String announcements = '$baseUrl/pengumuman';

  // Notification endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String notificationsUnreadCount =
      '$baseUrl/notifications/unread-count';
  static const String notificationsReadAll = '$baseUrl/notifications/read-all';
  static const String notificationsPreferences =
      '$baseUrl/notifications/preferences';
  // Untuk mark as read: notifications/{id}/read (POST)

  // FCM endpoints
  static const String fcmRegister = '$baseUrl/fcm/register';
  static const String fcmUnregister = '$baseUrl/fcm/unregister';
}
