import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized FlutterSecureStorage configuration
/// Use this instance throughout the app for consistency
class StorageConfig {
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // This forces the use of EncryptedSharedPreferences with AES-256-GCM
      // instead of the older AES-CBC mode
      // Note: Even with this setting, some older Android versions may still
      // fallback to CBC mode. Consider using additional encryption layers.
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Alternative: Use with additional encryption layer for extra security
  static const FlutterSecureStorage encryptedStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Force resetOnError to clear potentially corrupted data
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
}
