/// Konstanta untuk fitur Izin & Cuti

class LeaveConstants {
  LeaveConstants._();

  // API Endpoints (untuk implementasi masa depan)
  static const String getLeaveBalance = '/leave/balance';
  static const String getLeaveHistory = '/leave/history';
  static const String submitLeave = '/leave/submit';
  static const String cancelLeave = '/leave/cancel';
  static const String getLeaveDetail = '/leave/detail';
  static const String uploadDocument = '/leave/upload';

  // Jatah cuti default per tahun
  static const int defaultAnnualLeave = 12;
  static const int defaultPersonalLeave = 3;
  static const int defaultSickLeave = 14;
  static const int defaultMaternityLeave = 90;
  static const int defaultMarriageLeave = 3;

  // Batas waktu pengajuan (dalam hari sebelum tanggal mulai)
  static const int minimumAdvanceNotice = 3; // minimal 3 hari sebelumnya
  static const int sickLeaveAdvanceNotice = 0; // izin sakit bisa hari H
  
  // Maksimal file upload (dalam bytes)
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  
  // Format file yang diizinkan
  static const List<String> allowedFileExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  // Pesan error
  static const String errorNoConnection = 'Tidak dapat terhubung ke server';
  static const String errorInvalidDate = 'Tanggal tidak valid';
  static const String errorInsufficientBalance = 'Sisa cuti tidak mencukupi';
  static const String errorPastDate = 'Tidak dapat mengajukan cuti untuk tanggal yang sudah lewat';
  static const String errorWeekend = 'Tidak dapat mengajukan cuti di hari weekend';
  static const String errorOverlapping = 'Sudah ada pengajuan cuti di tanggal tersebut';
  static const String errorDocumentRequired = 'Dokumen pendukung wajib dilampirkan';
  static const String errorFileTooLarge = 'Ukuran file maksimal 5MB';
  static const String errorInvalidFileType = 'Format file tidak didukung';

  // Pesan sukses
  static const String successSubmit = 'Pengajuan berhasil dikirim';
  static const String successCancel = 'Pengajuan berhasil dibatalkan';

  // Label UI
  static const String labelSelectStartDate = 'Pilih Tanggal Mulai';
  static const String labelSelectEndDate = 'Pilih Tanggal Selesai';
  static const String labelReason = 'Alasan';
  static const String labelReasonHint = 'Jelaskan alasan pengajuan izin/cuti Anda...';
  static const String labelAttachment = 'Lampiran';
  static const String labelUploadDocument = 'Upload Dokumen';
  static const String labelSubmit = 'Ajukan';
  static const String labelCancel = 'Batalkan';
  static const String labelLeaveBalance = 'Sisa Cuti';
  static const String labelLeaveHistory = 'Riwayat Pengajuan';
  static const String labelNoHistory = 'Belum ada riwayat pengajuan';
  static const String labelDays = 'hari';
}
