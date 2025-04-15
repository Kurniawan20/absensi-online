import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _credentialsKey = 'saved_credentials';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastUserKey = 'last_user_email';
  static const String _appInitializedKey = 'app_initialized';

  Future<void> saveCredentials(String email, String password) async {
    final lastUser = await getLastUser();
    if (lastUser != null && lastUser != email) {
      // If the user is different, clear biometric settings
      await setBiometricEnabled(false);
    }
    
    final credentials = {
      'email': email,
      'password': password,
    };
    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials),
    );
    
    // Save the current user email
    await _storage.write(
      key: _lastUserKey,
      value: email,
    );

    // Mark app as initialized after first successful login
    await markAppInitialized();
  }

  Future<bool> isAppInitialized() async {
    final value = await _storage.read(key: _appInitializedKey);
    return value == 'true';
  }

  Future<void> markAppInitialized() async {
    await _storage.write(
      key: _appInitializedKey,
      value: 'true',
    );
  }

  Future<Map<String, String>?> getCredentials() async {
    final credentialsString = await _storage.read(key: _credentialsKey);
    if (credentialsString == null) return null;
    
    try {
      final credentials = json.decode(credentialsString) as Map<String, dynamic>;
      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
      };
    } catch (e) {
      return null;
    }
  }

  Future<String?> getLastUser() async {
    return await _storage.read(key: _lastUserKey);
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.delete(key: _lastUserKey);
    await setBiometricEnabled(false);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    print('Setting biometric enabled: $enabled');
    if (!enabled) {
      // When disabling biometric, only clear credentials
      await _storage.delete(key: _credentialsKey);
      await _storage.delete(key: _lastUserKey);
    }
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString().toLowerCase(),
    );
    print('Biometric enabled value saved: $enabled');
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    print('Current biometric enabled value: $value');
    return value?.toLowerCase() == 'true';
  }

  Future<bool> isCurrentUser(String email) async {
    final lastUser = await getLastUser();
    return lastUser == email;
  }

  // Handles complete logout
  Future<void> handleLogout() async {
    print('Handling secure storage logout...');
    // Clear credentials and biometric settings
    await deleteCredentials();
    // Do NOT clear app initialization status
    print('Secure storage logout complete');
  }

  // For testing/debugging only
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}
