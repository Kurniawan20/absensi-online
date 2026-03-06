import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service untuk memeriksa keamanan perangkat sebelum absensi.
/// Menggunakan device_info_plus untuk deteksi emulator.
/// Catatan: Deteksi root/jailbreak dihapus karena plugin-nya
/// mengandung native library yang tidak kompatibel dengan 16KB page size.
class SecurityService {
  static const SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  const SecurityService._internal();

  // Testing mode flag - set to true to bypass security checks even in release builds
  static const bool _isTestingMode = false;

  /// Check if the device is in a secure state for attendance
  Future<SecurityCheckResult> performSecurityCheck(
      {bool forceCheck = false}) async {
    try {
      // Skip security checks in testing mode
      if (_isTestingMode && !forceCheck) {
        return SecurityCheckResult(
          isSecure: true,
          violations: [],
          message: 'Testing mode - security checks bypassed',
        );
      }

      // Skip security checks in debug mode for development (unless forced)
      if (kDebugMode && !forceCheck) {
        return SecurityCheckResult(
          isSecure: true,
          violations: [],
          message: 'Debug mode - security checks bypassed',
        );
      }

      List<String> violations = [];

      // Cek apakah berjalan di emulator
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          violations.add('Running on emulator/simulator');
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          violations.add('Running on simulator');
        }
      }

      bool isSecure = violations.isEmpty;
      String message = isSecure
          ? 'Device is secure for attendance'
          : 'Security violations detected:\n${violations.join('\n')}';

      return SecurityCheckResult(
        isSecure: isSecure,
        violations: violations,
        message: message,
      );
    } catch (e) {
      print('Security check error: $e');
      // Jika terjadi error, anggap perangkat aman agar absensi tidak terblokir
      return SecurityCheckResult(
        isSecure: true,
        violations: [],
        message: 'Security check skipped due to error.',
      );
    }
  }

  /// Cek apakah berjalan di perangkat nyata (bukan emulator)
  Future<bool> isRealDevice() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice;
      }

      return true;
    } catch (e) {
      print('Real device check error: $e');
      return true; // Default ke true jika gagal cek
    }
  }
}

class SecurityCheckResult {
  final bool isSecure;
  final List<String> violations;
  final String message;

  const SecurityCheckResult({
    required this.isSecure,
    required this.violations,
    required this.message,
  });

  @override
  String toString() {
    return 'SecurityCheckResult(isSecure: $isSecure, violations: $violations, message: $message)';
  }
}
