import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class SecurityService {
  static const SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  const SecurityService._internal();

  /// Check if the device is in a secure state for attendance
  Future<SecurityCheckResult> performSecurityCheck({bool forceCheck = false}) async {
    try {
      // Skip security checks in debug mode for development (unless forced)
      if (kDebugMode && !forceCheck) {
        return SecurityCheckResult(
          isSecure: true,
          violations: [],
          message: 'Debug mode - security checks bypassed',
        );
      }

      List<String> violations = [];
      
      // Check if device is rooted/jailbroken
      bool isJailbroken = await FlutterJailbreakDetection.jailbroken;
      if (isJailbroken) {
        violations.add('Device is rooted/jailbroken');
      }

      // Check for developer options enabled (Android only)
      if (Platform.isAndroid) {
        bool isDeveloperModeEnabled = await FlutterJailbreakDetection.developerMode;
        if (isDeveloperModeEnabled) {
          violations.add('Developer options is enabled');
        }
      }

      // Check if running on real device
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      bool isRealDevice = true;
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Check if running on emulator
        isRealDevice = androidInfo.isPhysicalDevice;
        if (!isRealDevice) {
          violations.add('Running on emulator/simulator');
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        isRealDevice = iosInfo.isPhysicalDevice;
        if (!isRealDevice) {
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
      // In case of error, assume device is not secure for safety
      return SecurityCheckResult(
        isSecure: false,
        violations: ['Security check failed'],
        message: 'Unable to verify device security. Please ensure your device meets security requirements.',
      );
    }
  }

  /// Quick check specifically for developer mode
  Future<bool> isDeveloperModeEnabled() async {
    try {
      if (kDebugMode) return false; // Allow in debug mode
      if (Platform.isAndroid) {
        return await FlutterJailbreakDetection.developerMode;
      }
      return false; // iOS doesn't have developer mode in the same way
    } catch (e) {
      print('Developer mode check error: $e');
      return true; // Assume enabled if check fails for safety
    }
  }

  /// Quick check for jailbreak/root
  Future<bool> isJailbroken() async {
    try {
      if (kDebugMode) return false; // Allow in debug mode
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      print('Jailbreak check error: $e');
      return true; // Assume jailbroken if check fails for safety
    }
  }

  /// Check if running on real device
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
      
      return true; // Default to true for other platforms
    } catch (e) {
      print('Real device check error: $e');
      return false; // Assume emulator if check fails for safety
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
