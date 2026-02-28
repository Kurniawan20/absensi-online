import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../repository/device_reset_repository.dart';
import '../../models/device_reset_request.dart';
import 'device_reset_event.dart';
import 'device_reset_state.dart';

/// BLoC untuk mengelola request reset device
class DeviceResetBloc extends Bloc<DeviceResetEvent, DeviceResetState> {
  final DeviceResetRepository repository;

  DeviceResetBloc({required this.repository}) : super(const DeviceResetInitial()) {
    on<SubmitDeviceResetRequest>(_onSubmitRequest);
    on<ResetDeviceResetState>(_onResetState);
  }

  /// Handler untuk SubmitDeviceResetRequest event
  Future<void> _onSubmitRequest(
    SubmitDeviceResetRequest event,
    Emitter<DeviceResetState> emit,
  ) async {
    emit(const DeviceResetLoading());

    debugPrint('DeviceResetBloc: Submitting request');
    debugPrint('  NPP: ${event.npp}');
    debugPrint('  Reason: ${event.reason}');

    final result = await repository.submitResetRequest(
      npp: event.npp,
      reason: event.reason,
    );

    debugPrint('DeviceResetBloc: Result: $result');

    if (result['success'] == true) {
      final request = result['data'] as DeviceResetRequest;
      emit(DeviceResetSubmitSuccess(
        request: request,
        message: result['message'] ?? 'Permintaan berhasil diajukan',
      ));
    } else {
      final rcode = result['rcode']?.toString() ?? '';
      final message = result['message'] ?? 'Terjadi kesalahan';

      if (rcode == '81') {
        // User not found
        emit(DeviceResetUserNotFound(message: message));
      } else if (rcode == '82') {
        // Already has pending request
        emit(DeviceResetAlreadyPending(message: message));
      } else {
        // General error
        emit(DeviceResetSubmitFailed(message: message));
      }
    }
  }

  /// Handler untuk ResetDeviceResetState event
  void _onResetState(
    ResetDeviceResetState event,
    Emitter<DeviceResetState> emit,
  ) {
    emit(const DeviceResetInitial());
  }
}
