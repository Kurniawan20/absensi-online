/// Response codes untuk attendance API
/// Mapping response code API ke pesan dan skenario yang user-friendly
class AttendanceResponseCodes {
  // Kode sukses
  static const String success = '00';

  // Kode error untuk Absen Masuk (Check-in)
  static const String tooEarly = '01';
  static const String duplicateCheckIn = '02';

  // Kode error untuk Absen Pulang (Check-out)
  static const String noCheckIn = '03'; // Belum absen masuk
  static const String duplicateCheckOut = '04'; // Sudah absen pulang

  // Kode error umum
  static const String sessionExpired = '99';
  static const String deviceNotRegistered = '98';

  /// Mendapatkan pesan user-friendly untuk response check-in
  static AttendanceResponse getCheckInResponse(
    String rcode,
    String? apiMessage,
  ) {
    switch (rcode) {
      case success:
        return AttendanceResponse(
          isSuccess: true,
          title: 'Berhasil!',
          message: apiMessage ??
              'Absen masuk kamu sudah tercatat. Semangat bekerja hari ini!',
          icon: AttendanceIcon.success,
        );
      case tooEarly:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Terlalu Pagi',
          message: apiMessage ??
              'Belum bisa melakukan absen masuk. Waktu absen belum tiba.',
          icon: AttendanceIcon.tooEarly,
        );
      case duplicateCheckIn:
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

  /// Mendapatkan pesan user-friendly untuk response check-out
  static AttendanceResponse getCheckOutResponse(
    String rcode,
    String? apiMessage,
  ) {
    switch (rcode) {
      case success:
        return AttendanceResponse(
          isSuccess: true,
          title: 'Berhasil!',
          message: apiMessage ??
              'Absen pulang kamu sudah tercatat. Hati-hati di jalan dan selamat beristirahat!',
          icon: AttendanceIcon.success,
        );
      case noCheckIn:
        return AttendanceResponse(
          isSuccess: false,
          title: 'Belum Absen Masuk',
          message: apiMessage ?? 'Anda belum melakukan absen masuk hari ini.',
          icon: AttendanceIcon.warning,
        );
      case duplicateCheckOut:
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

/// Tipe ikon untuk response kehadiran
enum AttendanceIcon { success, tooEarly, duplicate, warning, error }

/// Model response kehadiran
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
