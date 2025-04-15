class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final double attendanceRate;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.attendanceRate,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    return AttendanceStatistics(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'late_days': lateDays,
      'absent_days': absentDays,
      'attendance_rate': attendanceRate,
    };
  }

  factory AttendanceStatistics.empty() {
    return AttendanceStatistics(
      totalDays: 0,
      presentDays: 0,
      lateDays: 0,
      absentDays: 0,
      attendanceRate: 0.0,
    );
  }
}
