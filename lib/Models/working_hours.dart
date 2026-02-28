/// Model for Working Hours / Jam Kerja
class WorkingHours {
  final int id;
  final String nama;
  final String startJamMasuk;
  final String? endJamMasuk;
  final String startJamPulang;
  final String? endJamPulang;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkingHours({
    required this.id,
    required this.nama,
    required this.startJamMasuk,
    this.endJamMasuk,
    required this.startJamPulang,
    this.endJamPulang,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      startJamMasuk: _formatTime(json['start_jam_masuk']),
      endJamMasuk: json['end_jam_masuk'] != null 
          ? _formatTime(json['end_jam_masuk']) 
          : null,
      startJamPulang: _formatTime(json['start_jam_pulang']),
      endJamPulang: json['end_jam_pulang'] != null 
          ? _formatTime(json['end_jam_pulang']) 
          : null,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  /// Format time from "HH:mm:ss" to "HH:mm"
  static String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    // Remove seconds if present (e.g., "07:00:00" -> "07:00")
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  /// Get formatted check-in time range
  String get checkInTimeRange {
    if (endJamMasuk != null) {
      return '$startJamMasuk - $endJamMasuk';
    }
    return startJamMasuk;
  }

  /// Get formatted check-out time range
  String get checkOutTimeRange {
    if (endJamPulang != null) {
      return '$startJamPulang - $endJamPulang';
    }
    return startJamPulang;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'start_jam_masuk': startJamMasuk,
      'end_jam_masuk': endJamMasuk,
      'start_jam_pulang': startJamPulang,
      'end_jam_pulang': endJamPulang,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'WorkingHours(id: $id, nama: $nama, masuk: $startJamMasuk-$endJamMasuk, pulang: $startJamPulang-$endJamPulang, active: $isActive)';
  }
}
