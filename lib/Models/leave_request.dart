import 'leave_type.dart';

/// Model untuk pengajuan izin/cuti
class LeaveRequest {
  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? attachmentPath;
  final String? attachmentName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? approverName;
  final String? approverNote;
  final String employeeId;
  final String employeeName;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.attachmentPath,
    this.attachmentName,
    required this.createdAt,
    this.updatedAt,
    this.approverName,
    this.approverNote,
    required this.employeeId,
    required this.employeeName,
  });

  /// Menghitung jumlah hari cuti
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Cek apakah pengajuan masih bisa dibatalkan
  bool get canBeCancelled {
    return status == LeaveStatus.pending && startDate.isAfter(DateTime.now());
  }

  /// Cek apakah cuti sedang berlangsung
  bool get isOngoing {
    final now = DateTime.now();
    return status == LeaveStatus.approved &&
        now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Cek apakah cuti sudah selesai
  bool get isCompleted {
    return status == LeaveStatus.approved && DateTime.now().isAfter(endDate);
  }

  /// Factory constructor dari JSON
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      type: LeaveType.values.firstWhere(
        (e) => e.toString() == 'LeaveType.${json['type']}',
        orElse: () => LeaveType.cutiTahunan,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String,
      status: LeaveStatus.values.firstWhere(
        (e) => e.toString() == 'LeaveStatus.${json['status']}',
        orElse: () => LeaveStatus.pending,
      ),
      attachmentPath: json['attachment_path'] as String?,
      attachmentName: json['attachment_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      approverName: json['approver_name'] as String?,
      approverNote: json['approver_note'] as String?,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reason': reason,
      'status': status.toString().split('.').last,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'approver_name': approverName,
      'approver_note': approverNote,
      'employee_id': employeeId,
      'employee_name': employeeName,
    };
  }

  /// Copy with method untuk immutability
  LeaveRequest copyWith({
    String? id,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveStatus? status,
    String? attachmentPath,
    String? attachmentName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approverName,
    String? approverNote,
    String? employeeId,
    String? employeeName,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approverName: approverName ?? this.approverName,
      approverNote: approverNote ?? this.approverNote,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  @override
  String toString() {
    return 'LeaveRequest(id: $id, type: ${type.name}, status: ${status.name}, '
        'startDate: $startDate, endDate: $endDate, totalDays: $totalDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model untuk saldo/jatah cuti
class LeaveBalance {
  final LeaveType type;
  final int totalAllowance;
  final int used;
  final int pending;

  LeaveBalance({
    required this.type,
    required this.totalAllowance,
    required this.used,
    this.pending = 0,
  });

  /// Sisa cuti yang tersedia
  int get remaining => totalAllowance - used - pending;

  /// Persentase yang sudah terpakai
  double get usedPercentage => 
      totalAllowance > 0 ? (used / totalAllowance) * 100 : 0;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: LeaveType.values.firstWhere(
        (e) => e.toString() == 'LeaveType.${json['type']}',
        orElse: () => LeaveType.cutiTahunan,
      ),
      totalAllowance: json['total_allowance'] as int,
      used: json['used'] as int,
      pending: json['pending'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'total_allowance': totalAllowance,
      'used': used,
      'pending': pending,
    };
  }
}
