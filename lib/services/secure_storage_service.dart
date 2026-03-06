import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/storage_config.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = StorageConfig.secureStorage;

  static const String _credentialsKey = 'saved_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastUserKey = 'last_user_email';
  static const String _appInitializedKey = 'app_initialized';

  /// Baca nilai dari secure storage dengan penanganan error dekripsi.
  /// Jika terjadi BAD_DECRYPT (misal setelah reinstall app), storage
  /// akan di-reset otomatis agar aplikasi tidak crash.
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('[SecureStorage] Gagal baca key "$key": $e');
      print(
          '[SecureStorage] Menghapus semua data karena kunci enkripsi tidak valid...');
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    final lastUser = await getLastUser();
    if (lastUser != null && lastUser != email) {
      await setBiometricEnabled(false);
    }
    final credentials = {'email': email, 'password': password};
    await _storage.write(key: _credentialsKey, value: json.encode(credentials));
    await _storage.write(key: _lastUserKey, value: email);
    await markAppInitialized();
  }

  Future<bool> isAppInitialized() async {
    final value = await _safeRead(_appInitializedKey);
    return value == 'true';
  }

  Future<void> markAppInitialized() async {
    await _storage.write(key: _appInitializedKey, value: 'true');
  }

  Future<Map<String, String>?> getCredentials() async {
    final credentialsString = await _safeRead(_credentialsKey);
    if (credentialsString == null) return null;
    try {
      final credentials =
          json.decode(credentialsString) as Map<String, dynamic>;
      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
      };
    } catch (e) {
      return null;
    }
  }

  Future<String?> getLastUser() async {
    return await _safeRead(_lastUserKey);
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.delete(key: _lastUserKey);
    await setBiometricEnabled(false);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (!enabled) {
      await _storage.delete(key: _credentialsKey);
      await _storage.delete(key: _lastUserKey);
    }
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString().toLowerCase(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _safeRead(_biometricEnabledKey);
    return value?.toLowerCase() == 'true';
  }

  Future<bool> isCurrentUser(String email) async {
    final lastUser = await getLastUser();
    return lastUser == email;
  }

  Future<void> handleLogout() async {
    await deleteCredentials();
  }

  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}
