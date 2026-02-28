class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int lateDays;
  final int onTimeDays;
  final int absentDays;
  final double attendanceRate;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
    required this.onTimeDays,
    required this.absentDays,
    required this.attendanceRate,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    final totalDays = _parseInt(json['total_days']);
    final lateDays = _parseInt(json['late_days']);
    final onTimeDays = _parseInt(json['on_time_days']);
    final absentDays = _parseInt(json['absent_days']);
    
    // Calculate present days (late + on_time) if not provided
    final presentDays = json['present_days'] != null 
        ? _parseInt(json['present_days'])
        : lateDays + onTimeDays;
    
    // Calculate attendance rate if not provided
    final attendanceRate = json['attendance_rate'] != null
        ? (json['attendance_rate'] is double 
            ? json['attendance_rate'] 
            : double.tryParse(json['attendance_rate'].toString()) ?? 0.0)
        : (totalDays > 0 ? (presentDays / totalDays * 100) : 0.0);

    return AttendanceStatistics(
      totalDays: totalDays,
      presentDays: presentDays,
      lateDays: lateDays,
      onTimeDays: onTimeDays,
      absentDays: absentDays,
      attendanceRate: attendanceRate,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'late_days': lateDays,
      'on_time_days': onTimeDays,
      'absent_days': absentDays,
      'attendance_rate': attendanceRate,
    };
  }

  factory AttendanceStatistics.empty() {
    return AttendanceStatistics(
      totalDays: 0,
      presentDays: 0,
      lateDays: 0,
      onTimeDays: 0,
      absentDays: 0,
      attendanceRate: 0.0,
    );
  }
}
