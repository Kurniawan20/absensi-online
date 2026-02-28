import 'package:equatable/equatable.dart';

/// Model untuk menyimpan data request reset device
class DeviceResetRequest extends Equatable {
  /// ID request
  final int id;

  /// NPP karyawan
  final String npp;

  /// Device ID lama yang akan di-reset
  final String? oldDeviceId;

  /// Alasan reset device
  final String reason;

  /// Status request: pending, approved, rejected
  final String status;

  /// Admin yang memproses request
  final String? processedBy;

  /// Waktu diproses oleh admin
  final DateTime? processedAt;

  /// Catatan dari admin
  final String? adminNotes;

  /// Waktu request dibuat
  final DateTime createdAt;

  const DeviceResetRequest({
    required this.id,
    required this.npp,
    this.oldDeviceId,
    required this.reason,
    required this.status,
    this.processedBy,
    this.processedAt,
    this.adminNotes,
    required this.createdAt,
  });

  /// Factory constructor untuk parsing dari JSON response API
  factory DeviceResetRequest.fromJson(Map<String, dynamic> json) {
    return DeviceResetRequest(
      id: json['id'] ?? 0,
      npp: json['npp'] ?? '',
      oldDeviceId: json['old_device_id'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      processedBy: json['processed_by'],
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'])
          : null,
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'npp': npp,
      'old_device_id': oldDeviceId,
      'reason': reason,
      'status': status,
      'processed_by': processedBy,
      'processed_at': processedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check apakah status pending
  bool get isPending => status == 'pending';

  /// Check apakah status approved
  bool get isApproved => status == 'approved';

  /// Check apakah status rejected
  bool get isRejected => status == 'rejected';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Menunggu Approval';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        npp,
        oldDeviceId,
        reason,
        status,
        processedBy,
        processedAt,
        adminNotes,
        createdAt,
      ];

  @override
  String toString() {
    return 'DeviceResetRequest(id: $id, npp: $npp, status: $status, reason: $reason)';
  }
}
