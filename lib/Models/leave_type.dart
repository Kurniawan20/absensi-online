import 'package:flutter/material.dart';

/// Enum untuk jenis-jenis izin/cuti
enum LeaveType {
  cutiTahunan,
  izinPribadi,
  izinSakit,
  cutiMelahirkan,
  cutiMenikah,
}

/// Extension untuk mendapatkan informasi detail setiap jenis cuti
extension LeaveTypeExtension on LeaveType {
  String get name {
    switch (this) {
      case LeaveType.cutiTahunan:
        return 'Cuti Tahunan';
      case LeaveType.izinPribadi:
        return 'Izin Pribadi';
      case LeaveType.izinSakit:
        return 'Izin Sakit';
      case LeaveType.cutiMelahirkan:
        return 'Cuti Melahirkan';
      case LeaveType.cutiMenikah:
        return 'Cuti Menikah';
    }
  }

  String get description {
    switch (this) {
      case LeaveType.cutiTahunan:
        return 'Jatah cuti tahunan karyawan';
      case LeaveType.izinPribadi:
        return 'Izin untuk keperluan pribadi';
      case LeaveType.izinSakit:
        return 'Izin karena kondisi kesehatan';
      case LeaveType.cutiMelahirkan:
        return 'Cuti untuk karyawati melahirkan';
      case LeaveType.cutiMenikah:
        return 'Cuti untuk pernikahan';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveType.cutiTahunan:
        return Icons.calendar_today_rounded;
      case LeaveType.izinPribadi:
        return Icons.person_outline_rounded;
      case LeaveType.izinSakit:
        return Icons.local_hospital_rounded;
      case LeaveType.cutiMelahirkan:
        return Icons.child_friendly_rounded;
      case LeaveType.cutiMenikah:
        return Icons.favorite_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LeaveType.cutiTahunan:
        return const Color(0xFF016541); // Green
      case LeaveType.izinPribadi:
        return const Color(0xFF1565C0); // Blue
      case LeaveType.izinSakit:
        return const Color(0xFFE65100); // Orange
      case LeaveType.cutiMelahirkan:
        return const Color(0xFFAD1457); // Pink
      case LeaveType.cutiMenikah:
        return const Color(0xFFC62828); // Red
    }
  }

  /// Apakah jenis cuti ini memerlukan dokumen pendukung
  bool get requiresDocument {
    switch (this) {
      case LeaveType.izinSakit:
      case LeaveType.cutiMelahirkan:
        return true;
      default:
        return false;
    }
  }

  /// Maksimal hari yang bisa diambil
  int get maxDays {
    switch (this) {
      case LeaveType.cutiTahunan:
        return 12;
      case LeaveType.izinPribadi:
        return 3;
      case LeaveType.izinSakit:
        return 14;
      case LeaveType.cutiMelahirkan:
        return 90;
      case LeaveType.cutiMenikah:
        return 3;
    }
  }
}

/// Status pengajuan izin/cuti
enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

extension LeaveStatusExtension on LeaveStatus {
  String get name {
    switch (this) {
      case LeaveStatus.pending:
        return 'Menunggu';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
      case LeaveStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case LeaveStatus.approved:
        return const Color(0xFF10B981); // Green
      case LeaveStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case LeaveStatus.cancelled:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeaveStatus.pending:
        return const Color(0xFFFEF3C7); // Light Amber
      case LeaveStatus.approved:
        return const Color(0xFFD1FAE5); // Light Green
      case LeaveStatus.rejected:
        return const Color(0xFFFEE2E2); // Light Red
      case LeaveStatus.cancelled:
        return const Color(0xFFF3F4F6); // Light Gray
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveStatus.pending:
        return Icons.schedule_rounded;
      case LeaveStatus.approved:
        return Icons.check_circle_rounded;
      case LeaveStatus.rejected:
        return Icons.cancel_rounded;
      case LeaveStatus.cancelled:
        return Icons.remove_circle_rounded;
    }
  }
}
