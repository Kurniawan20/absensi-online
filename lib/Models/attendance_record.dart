class AttendanceRecord {
  final DateTime date;
  final String checkInTime;
  final String checkOutTime;
  final String notes;
  final String type;
  final bool isLate;
  final String? batasJamMasuk;

  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.notes,
    required this.type,
    required this.isLate,
    this.batasJamMasuk,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final checkIn = json['jam_masuk'] ?? '--:--';
    final notes = json['ket_absensi'] ?? '-';
    
    // Get is_late from API response (no more hardcoded logic)
    final isLate = json['is_late'] == true || json['is_late'] == 1;
    
    // Determine type based on API data
    String determineType(String? checkInTime, String? notes, bool isLate) {
      if (notes?.toLowerCase().contains('tidak hadir') ?? false) {
        return 'absent';
      }
      if (checkInTime == null || checkInTime == '--:--') {
        return 'absent';
      }
      if (isLate) {
        return 'late';
      }
      return 'present';
    }
    
    return AttendanceRecord(
      date: DateTime.parse(json['tanggal']),
      checkInTime: checkIn,
      checkOutTime: json['jam_keluar'] ?? '--:--',
      notes: notes,
      type: determineType(checkIn, notes, isLate),
      isLate: isLate,
      batasJamMasuk: json['batas_jam_masuk'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': date.toIso8601String().split('T')[0],
      'jam_masuk': checkInTime,
      'jam_keluar': checkOutTime,
      'ket_absensi': notes,
      'type': type,
      'is_late': isLate,
      'batas_jam_masuk': batasJamMasuk,
    };
  }
}
