import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/attendance_record.dart';
import '../../repository/attendance_recap_repository.dart';
import 'attendance_recap_event.dart';
import 'attendance_recap_state.dart';

class AttendanceRecapBloc
    extends Bloc<AttendanceRecapEvent, AttendanceRecapState> {
  final AttendanceRecapRepository repository;

  AttendanceRecapBloc({required this.repository})
      : super(AttendanceRecapInitial()) {
    on<LoadAttendanceHistory>(_onLoadAttendanceHistory);
    on<GenerateAttendanceReport>(_onGenerateReport);
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceRecapState> emit,
  ) async {
    try {
      emit(AttendanceRecapLoading());

      final result = await repository.getAttendanceHistory(
        npp: event.npp,
        year: event.year,
        month: event.month,
      );

      if (result['success']) {
        final List<AttendanceRecord> records = result['records'];
        emit(AttendanceRecapLoaded(records: records));
      } else {
        emit(AttendanceRecapError(message: result['error']));
      }
    } catch (e) {
      emit(AttendanceRecapError(message: e.toString()));
    }
  }

  Future<void> _onGenerateReport(
    GenerateAttendanceReport event,
    Emitter<AttendanceRecapState> emit,
  ) async {
    try {
      emit(AttendanceRecapLoading());

      final result = await repository.generateAttendanceReport(
        npp: event.npp,
        year: event.year,
        month: event.month,
        reportType: event.reportType,
      );

      if (result['success']) {
        emit(AttendanceReportGenerateSuccess(
          reportUrl: result['url'],
          reportType: event.reportType,
        ));
      } else {
        emit(AttendanceRecapError(message: result['error']));
      }
    } catch (e) {
      emit(AttendanceRecapError(message: e.toString()));
    }
  }
}
