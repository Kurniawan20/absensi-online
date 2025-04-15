import 'package:equatable/equatable.dart';

abstract class AttendanceRecapEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAttendanceHistory extends AttendanceRecapEvent {
  final String npp;
  final int year;
  final int month;

  LoadAttendanceHistory({
    required this.npp,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [npp, year, month];
}

class GenerateAttendanceReport extends AttendanceRecapEvent {
  final String npp;
  final int year;
  final int month;
  final String reportType;

  GenerateAttendanceReport({
    required this.npp,
    required this.year,
    required this.month,
    required this.reportType,
  });

  @override
  List<Object?> get props => [npp, year, month, reportType];
}
