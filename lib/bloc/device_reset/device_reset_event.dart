import 'package:equatable/equatable.dart';

/// Base class untuk semua Device Reset events
abstract class DeviceResetEvent extends Equatable {
  const DeviceResetEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk submit request reset device
class SubmitDeviceResetRequest extends DeviceResetEvent {
  final String npp;
  final String reason;

  const SubmitDeviceResetRequest({
    required this.npp,
    required this.reason,
  });

  @override
  List<Object?> get props => [npp, reason];
}

/// Event untuk reset state ke initial
class ResetDeviceResetState extends DeviceResetEvent {
  const ResetDeviceResetState();
}
