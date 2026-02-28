import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../../repository/app_version_repository.dart';
import '../../models/app_version_info.dart';
import 'app_version_event.dart';
import 'app_version_state.dart';

/// BLoC untuk mengelola pengecekan versi aplikasi
class AppVersionBloc extends Bloc<AppVersionEvent, AppVersionState> {
  final AppVersionRepository repository;

  AppVersionBloc({required this.repository}) : super(const AppVersionInitial()) {
    on<CheckAppVersion>(_onCheckVersion);
    on<SkipOptionalUpdate>(_onSkipUpdate);
    on<RetryVersionCheck>(_onRetryVersionCheck);
    on<UpdateRetryStatus>(_onUpdateRetryStatus);
  }

  /// Handler untuk CheckAppVersion event
  Future<void> _onCheckVersion(
    CheckAppVersion event,
    Emitter<AppVersionState> emit,
  ) async {
    emit(const AppVersionChecking());

    try {
      // Get current app info
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final versionCode = packageInfo.version;

      debugPrint('AppVersionBloc: Starting version check');
      debugPrint('  Platform: $platform');
      debugPrint('  Build Number: $buildNumber');
      debugPrint('  Version: $versionCode');

      // Call repository dengan callback untuk retry status
      final result = await repository.checkVersion(
        platform: platform,
        buildNumber: buildNumber,
        versionCode: versionCode,
        onRetry: (retryCount, nextRetrySeconds) {
          // Emit retry status untuk UI update
          add(UpdateRetryStatus(
            retryCount: retryCount,
            nextRetrySeconds: nextRetrySeconds,
          ));
        },
      );

      if (result['success'] == true) {
        final info = result['data'] as AppVersionInfo;
        _handleVersionInfo(info, emit);
      } else {
        emit(AppVersionCheckFailed(
          error: result['error'] ?? 'Unknown error',
        ));
      }
    } catch (e) {
      debugPrint('AppVersionBloc: Error during version check: $e');
      emit(AppVersionCheckFailed(error: e.toString()));
    }
  }

  /// Handler untuk SkipOptionalUpdate event
  void _onSkipUpdate(
    SkipOptionalUpdate event,
    Emitter<AppVersionState> emit,
  ) {
    debugPrint('AppVersionBloc: User skipped optional update');
    emit(const AppVersionUpToDate());
  }

  /// Handler untuk RetryVersionCheck event (manual retry)
  Future<void> _onRetryVersionCheck(
    RetryVersionCheck event,
    Emitter<AppVersionState> emit,
  ) async {
    debugPrint('AppVersionBloc: Manual retry requested');
    add(const CheckAppVersion());
  }

  /// Handler untuk UpdateRetryStatus event (internal)
  void _onUpdateRetryStatus(
    UpdateRetryStatus event,
    Emitter<AppVersionState> emit,
  ) {
    emit(AppVersionChecking(
      retryCount: event.retryCount,
      nextRetrySeconds: event.nextRetrySeconds,
    ));
  }

  /// Process version info dan emit appropriate state
  void _handleVersionInfo(
    AppVersionInfo info,
    Emitter<AppVersionState> emit,
  ) {
    debugPrint('AppVersionBloc: Processing version info');
    debugPrint('  Maintenance Mode: ${info.maintenanceMode}');
    debugPrint('  Force Update: ${info.forceUpdate}');
    debugPrint('  Needs Update: ${info.needsUpdate}');

    if (info.maintenanceMode) {
      // Aplikasi dalam maintenance
      emit(AppVersionMaintenance(
        message: info.maintenanceMessage ?? 
            'Aplikasi sedang dalam pemeliharaan. Silakan coba lagi nanti.',
      ));
    } else if (info.forceUpdate) {
      // Force update diperlukan
      emit(AppVersionUpdateAvailable(
        info: info,
        isForced: true,
      ));
    } else if (info.needsUpdate) {
      // Optional update tersedia
      emit(AppVersionUpdateAvailable(
        info: info,
        isForced: false,
      ));
    } else {
      // Aplikasi sudah up to date
      emit(const AppVersionUpToDate());
    }
  }
}
