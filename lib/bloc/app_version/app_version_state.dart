import 'package:equatable/equatable.dart';
import '../../models/app_version_info.dart';

/// Base class untuk semua App Version states
abstract class AppVersionState extends Equatable {
  const AppVersionState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum pengecekan dimulai
class AppVersionInitial extends AppVersionState {
  const AppVersionInitial();
}

/// State saat sedang melakukan pengecekan versi
class AppVersionChecking extends AppVersionState {
  final int retryCount;
  final int? nextRetrySeconds;

  const AppVersionChecking({
    this.retryCount = 0,
    this.nextRetrySeconds,
  });

  @override
  List<Object?> get props => [retryCount, nextRetrySeconds];
}

/// State ketika aplikasi sudah up to date
class AppVersionUpToDate extends AppVersionState {
  const AppVersionUpToDate();
}

/// State ketika ada update tersedia
class AppVersionUpdateAvailable extends AppVersionState {
  final AppVersionInfo info;
  final bool isForced;

  const AppVersionUpdateAvailable({
    required this.info,
    required this.isForced,
  });

  @override
  List<Object?> get props => [info, isForced];
}

/// State ketika aplikasi dalam mode maintenance
class AppVersionMaintenance extends AppVersionState {
  final String message;

  const AppVersionMaintenance({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State ketika terjadi network error (dengan info retry)
class AppVersionNetworkError extends AppVersionState {
  final int retryCount;
  final int nextRetrySeconds;
  final String errorMessage;

  const AppVersionNetworkError({
    required this.retryCount,
    required this.nextRetrySeconds,
    this.errorMessage = 'Tidak dapat terhubung ke server',
  });

  @override
  List<Object?> get props => [retryCount, nextRetrySeconds, errorMessage];
}

/// State ketika pengecekan gagal (untuk error yang tidak bisa di-retry)
class AppVersionCheckFailed extends AppVersionState {
  final String error;

  const AppVersionCheckFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
