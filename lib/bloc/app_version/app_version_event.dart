import 'package:equatable/equatable.dart';

/// Base class untuk semua App Version events
abstract class AppVersionEvent extends Equatable {
  const AppVersionEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memulai pengecekan versi aplikasi
class CheckAppVersion extends AppVersionEvent {
  const CheckAppVersion();
}

/// Event untuk skip optional update
class SkipOptionalUpdate extends AppVersionEvent {
  const SkipOptionalUpdate();
}

/// Event untuk retry manual (dari tombol "Coba Lagi")
class RetryVersionCheck extends AppVersionEvent {
  const RetryVersionCheck();
}

/// Event internal untuk update retry count
class UpdateRetryStatus extends AppVersionEvent {
  final int retryCount;
  final int nextRetrySeconds;

  const UpdateRetryStatus({
    required this.retryCount,
    required this.nextRetrySeconds,
  });

  @override
  List<Object?> get props => [retryCount, nextRetrySeconds];
}
