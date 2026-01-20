import 'package:equatable/equatable.dart';
import '../../models/leave_type.dart';

/// Base class untuk semua Leave Events
abstract class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk load saldo cuti
class LoadLeaveBalance extends LeaveEvent {}

/// Event untuk load riwayat pengajuan
class LoadLeaveHistory extends LeaveEvent {
  final LeaveStatus? statusFilter;
  final LeaveType? typeFilter;
  final int page;
  final bool refresh;

  const LoadLeaveHistory({
    this.statusFilter,
    this.typeFilter,
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [statusFilter, typeFilter, page, refresh];
}

/// Event untuk load pengajuan terbaru (dashboard)
class LoadRecentRequests extends LeaveEvent {
  final int limit;

  const LoadRecentRequests({this.limit = 3});

  @override
  List<Object?> get props => [limit];
}

/// Event untuk load detail pengajuan
class LoadLeaveDetail extends LeaveEvent {
  final String id;

  const LoadLeaveDetail({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event untuk submit pengajuan baru
class SubmitLeaveRequest extends LeaveEvent {
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? attachmentPath;
  final String? attachmentName;

  const SubmitLeaveRequest({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.attachmentPath,
    this.attachmentName,
  });

  @override
  List<Object?> get props => [
        type,
        startDate,
        endDate,
        reason,
        attachmentPath,
        attachmentName,
      ];
}

/// Event untuk batalkan pengajuan
class CancelLeaveRequest extends LeaveEvent {
  final String id;

  const CancelLeaveRequest({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event untuk refresh semua data
class RefreshLeaveData extends LeaveEvent {}

/// Event untuk reset state (clear errors, etc)
class ResetLeaveState extends LeaveEvent {}
