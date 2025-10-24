class ApiConstants {
  // Base URL for the API endpoints
  static const String BASE_URL = "https://abs.basitd.net/api-absensi-mobile-v2/public/api";

  // Auth endpoints
  static const String LOGIN = '$BASE_URL/login';
  static const String KANTOR = '$BASE_URL/kantor';

  // Attendance endpoints
  static const String ATTENDANCE_HISTORY = '$BASE_URL/getabsen';
  static const String GENERATE_REPORT = '$BASE_URL/generatereport';

  // Legacy endpoints (to be removed)
  @deprecated
  static const String login = LOGIN;
  @deprecated
  static const String kantor = KANTOR;
  @deprecated
  static const String getabsen = ATTENDANCE_HISTORY;
}
