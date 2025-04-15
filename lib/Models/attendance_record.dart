class AttendanceRecord {
  final DateTime date;
  final String checkInTime;
  final String checkOutTime;
  final String notes;
  final String type;

  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.notes,
    required this.type,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    String determineType(String? checkInTime, String? notes) {
      if (notes?.toLowerCase().contains('tidak hadir') ?? false) {
        return 'absent';
      }
      if (checkInTime == null || checkInTime == '--:--') {
        return 'absent';
      }
      // Parse check-in time
      final timeStr = checkInTime.split(':');
      if (timeStr.length == 2) {
        final hour = int.tryParse(timeStr[0]);
        if (hour != null && hour > 8) {
          return 'late';
        }
      }
      return 'present';
    }

    final checkIn = json['jam_masuk'] ?? '--:--';
    final notes = json['ket_absensi'] ?? '-';
    
    return AttendanceRecord(
      date: DateTime.parse(json['tanggal']),
      checkInTime: checkIn,
      checkOutTime: json['jam_keluar'] ?? '--:--',
      notes: notes,
      type: determineType(checkIn, notes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': date.toIso8601String().split('T')[0],
      'jam_masuk': checkInTime,
      'jam_keluar': checkOutTime,
      'ket_absensi': notes,
      'type': type,
    };
  }
}
