import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_id/android_id.dart';

/// Service untuk mengambil informasi device
/// Digunakan untuk mengirim device info ke backend saat login
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic>? _cachedInfo;
  String? _cachedDeviceId;

  /// Get device info sesuai format API backend
  /// 
  /// Returns Map dengan format:
  /// ```json
  /// {
  ///   "platform": "android",
  ///   "brand": "Samsung",
  ///   "model": "SM-A515F",
  ///   "device_name": "Galaxy A51",
  ///   "manufacturer": "samsung",
  ///   "os_version": "13",
  ///   "sdk_version": 33,
  ///   "is_physical_device": true,
  ///   "build_id": "RP1A.200720.012",
  ///   "fingerprint": "samsung/...",
  ///   "hardware": "qcom",
  ///   "product": "a51nsxx",
  ///   "app_version": "2.1.0",
  ///   "app_build_number": 25
  /// }
  /// ```
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;

      _cachedInfo = {
        'platform': 'android',
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'device_name': androidInfo.device,
        'manufacturer': androidInfo.manufacturer,
        'os_version': androidInfo.version.release,
        'sdk_version': androidInfo.version.sdkInt,
        'is_physical_device': androidInfo.isPhysicalDevice,
        'build_id': androidInfo.id,
        'fingerprint': androidInfo.fingerprint,
        'hardware': androidInfo.hardware,
        'product': androidInfo.product,
        'app_version': packageInfo.version,
        'app_build_number': int.tryParse(packageInfo.buildNumber) ?? 0,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;

      _cachedInfo = {
        'platform': 'ios',
        'brand': 'Apple',
        'model': iosInfo.utsname.machine,
        'device_name': iosInfo.name,
        'manufacturer': 'Apple',
        'os_version': iosInfo.systemVersion,
        'is_physical_device': iosInfo.isPhysicalDevice,
        'build_id': iosInfo.identifierForVendor ?? '',
        'app_version': packageInfo.version,
        'app_build_number': int.tryParse(packageInfo.buildNumber) ?? 0,
      };
    }

    return _cachedInfo ?? {};
  }

  /// Get unique device ID
  /// 
  /// Android: Uses AndroidId package
  /// iOS: Uses identifierForVendor
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    if (Platform.isAndroid) {
      _cachedDeviceId = await const AndroidId().getId() ?? '';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _cachedDeviceId = iosInfo.identifierForVendor ?? '';
    }

    return _cachedDeviceId ?? '';
  }

  /// Get device info as formatted string for logging
  Future<String> getDeviceInfoString() async {
    final info = await getDeviceInfo();
    return '${info['brand']} ${info['model']} (${info['os_version']})';
  }

  /// Clear cached info (call when app restarts or user logs out)
  void clearCache() {
    _cachedInfo = null;
    _cachedDeviceId = null;
  }
}
