import 'package:equatable/equatable.dart';

/// Model untuk menyimpan informasi versi aplikasi dari server
class AppVersionInfo extends Equatable {
  /// Apakah update tersedia
  final bool needsUpdate;

  /// Apakah update wajib (force update)
  final bool forceUpdate;

  /// Apakah aplikasi dalam mode maintenance
  final bool maintenanceMode;

  /// Pesan update dari server
  final String? updateMessage;

  /// Pesan maintenance dari server
  final String? maintenanceMessage;

  /// URL store untuk download update
  final String? storeUrl;

  /// Changelog/catatan perubahan
  final String? changelog;

  const AppVersionInfo({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.maintenanceMode,
    this.updateMessage,
    this.maintenanceMessage,
    this.storeUrl,
    this.changelog,
  });

  /// Factory constructor untuk parsing dari JSON response API
  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      needsUpdate: json['needs_update'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      maintenanceMode: json['maintenance_mode'] ?? false,
      updateMessage: json['update_message'],
      maintenanceMessage: json['maintenance_message'],
      storeUrl: json['store_url'],
      changelog: json['changelog'],
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'needs_update': needsUpdate,
      'force_update': forceUpdate,
      'maintenance_mode': maintenanceMode,
      'update_message': updateMessage,
      'maintenance_message': maintenanceMessage,
      'store_url': storeUrl,
      'changelog': changelog,
    };
  }

  /// Default state - tidak ada update, tidak maintenance
  factory AppVersionInfo.upToDate() {
    return const AppVersionInfo(
      needsUpdate: false,
      forceUpdate: false,
      maintenanceMode: false,
    );
  }

  @override
  List<Object?> get props => [
        needsUpdate,
        forceUpdate,
        maintenanceMode,
        updateMessage,
        maintenanceMessage,
        storeUrl,
        changelog,
      ];

  @override
  String toString() {
    return 'AppVersionInfo(needsUpdate: $needsUpdate, forceUpdate: $forceUpdate, '
        'maintenanceMode: $maintenanceMode, updateMessage: $updateMessage, '
        'maintenanceMessage: $maintenanceMessage, storeUrl: $storeUrl)';
  }
}
