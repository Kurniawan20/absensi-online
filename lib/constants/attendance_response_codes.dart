/// Response codes for attendance API
/// Maps API response codes to user-friendly messages and scenarios
class AttendanceResponseCodes {
  // Success codes
  static const String SUCCESS = '00';

  // Error codes for Absen Masuk (Check-in)
  static const String TOO_EARLY = '01';
  static const String DUPLICATE_CHECK_IN = '02';

  // Error codes for Absen Pulang (Check-out)
  static const String NO_CHECK_IN = '03'; // Haven't checked in yet
  static const String DUPLICATE_CHECK_OUT = '04'; // Already checked out

  // General error codes
  static const String SESSION_EXPIRED = '99';
  static const String DEVICE_NOT_REGISTERED = '98';

  /// Get user-friendly message for check-in response
  static AttendanceResponse getCheckInResponse(
    String rcode,
    String? apiMessage,
  ) {
    switch (rcode) {
      case SUCCESS:
        return AttendanceResponse(
          isSuccess: true,
          title: 'Berhasil!',
          message:
              apiMessage ??
              'Absen masuk kamu sudah tercatat. Semangat bekerja hari ini!',
          icon: AttendanceIcon.success,
        );
      case TOO_EARLY:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Terlalu Pagi',
          message:
              apiMessage ??
              'Belum bisa melakukan absen masuk. Waktu absen belum tiba.',
          icon: AttendanceIcon.tooEarly,
        );
      case DUPLICATE_CHECK_IN:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Sudah Absen',
          message: apiMessage ?? 'Anda telah melakukan absen masuk hari ini.',
          icon: AttendanceIcon.warning,
        );
      default:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Gagal',
          message: apiMessage ?? 'Terjadi kesalahan saat absen masuk.',
          icon: AttendanceIcon.error,
        );
    }
  }

  /// Get user-friendly message for check-out response
  static AttendanceResponse getCheckOutResponse(
    String rcode,
    String? apiMessage,
  ) {
    switch (rcode) {
      case SUCCESS:
        return AttendanceResponse(
          isSuccess: true,
          title: 'Berhasil!',
          message:
              apiMessage ??
              'Absen pulang kamu sudah tercatat. Hati-hati di jalan dan selamat beristirahat!',
          icon: AttendanceIcon.success,
        );
      case NO_CHECK_IN:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Belum Absen Masuk',
          message: apiMessage ?? 'Anda belum melakukan absen masuk hari ini.',
          icon: AttendanceIcon.warning,
        );
      case DUPLICATE_CHECK_OUT:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Sudah Absen Pulang',
          message: apiMessage ?? 'Anda telah melakukan absen pulang hari ini.',
          icon: AttendanceIcon.duplicate,
        );
      default:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Gagal',
          message: apiMessage ?? 'Terjadi kesalahan saat absen pulang.',
          icon: AttendanceIcon.error,
        );
    }
  }
}

/// Icon types for attendance responses
enum AttendanceIcon { success, tooEarly, duplicate, warning, error }

/// Attendance response model
class AttendanceResponse {
  final bool isSuccess;
  final String title;
  final String message;
  final AttendanceIcon icon;

  const AttendanceResponse({
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.icon,
  });
}
