import 'package:equatable/equatable.dart';
import '../../models/device_reset_request.dart';

/// Base class untuk semua Device Reset states
abstract class DeviceResetState extends Equatable {
  const DeviceResetState();

  @override
  List<Object?> get props => [];
}

/// State awal
class DeviceResetInitial extends DeviceResetState {
  const DeviceResetInitial();
}

/// State saat loading/submitting
class DeviceResetLoading extends DeviceResetState {
  const DeviceResetLoading();
}

/// State ketika submit berhasil
class DeviceResetSubmitSuccess extends DeviceResetState {
  final DeviceResetRequest request;
  final String message;

  const DeviceResetSubmitSuccess({
    required this.request,
    required this.message,
  });

  @override
  List<Object?> get props => [request, message];
}

/// State ketika submit gagal (error umum)
class DeviceResetSubmitFailed extends DeviceResetState {
  final String message;

  const DeviceResetSubmitFailed({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State ketika user sudah memiliki pending request (rcode 82)
class DeviceResetAlreadyPending extends DeviceResetState {
  final String message;

  const DeviceResetAlreadyPending({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State ketika user tidak ditemukan (rcode 81)
class DeviceResetUserNotFound extends DeviceResetState {
  final String message;

  const DeviceResetUserNotFound({required this.message});

  @override
  List<Object?> get props => [message];
}
