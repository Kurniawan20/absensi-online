import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized FlutterSecureStorage configuration
/// Use this instance throughout the app for consistency
class StorageConfig {
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // This forces the use of EncryptedSharedPreferences with AES-256-GCM
      // instead of the older AES-CBC mode
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
}
