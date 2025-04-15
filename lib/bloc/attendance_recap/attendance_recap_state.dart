import 'package:equatable/equatable.dart';
import '../../models/attendance_record.dart';

abstract class AttendanceRecapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AttendanceRecapInitial extends AttendanceRecapState {}

class AttendanceRecapLoading extends AttendanceRecapState {}

class AttendanceRecapLoaded extends AttendanceRecapState {
  final List<AttendanceRecord> records;

  AttendanceRecapLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class AttendanceReportGenerateSuccess extends AttendanceRecapState {
  final String reportUrl;
  final String reportType;

  AttendanceReportGenerateSuccess({
    required this.reportUrl,
    required this.reportType,
  });

  @override
  List<Object?> get props => [reportUrl, reportType];
}

class AttendanceRecapError extends AttendanceRecapState {
  final String message;

  AttendanceRecapError({required this.message});

  @override
  List<Object?> get props => [message];
}
