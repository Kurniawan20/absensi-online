import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      print('Checking biometric availability...');
      
      // First check if device supports biometric
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print('Device supports biometric: $isDeviceSupported');
      if (!isDeviceSupported) {
        print('Device does not support biometric');
        return false;
      }

      // Then check if we can use biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('Can check biometrics: $canCheckBiometrics');
      if (!canCheckBiometrics) {
        print('Cannot check biometrics');
        return false;
      }

      // Get list of available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');
      
      // Check for any biometric support (fingerprint, face, or strong)
      final hasBiometric = availableBiometrics.contains(BiometricType.fingerprint) ||
                           availableBiometrics.contains(BiometricType.strong) ||
                           availableBiometrics.contains(BiometricType.face);
      print('Has biometric capability: $hasBiometric');
      
      return hasBiometric;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      print('Getting available biometrics...');
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $biometrics');
      return biometrics;
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate() async {
    try {
      print('Starting biometric authentication...');
      
      // First check if we can authenticate
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      
      print('Can check biometrics: $canCheck');
      print('Device supported: $isSupported');
      
      if (!canCheck || !isSupported) {
        print('Device does not support biometric authentication');
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');
      
      // Check for any biometric (fingerprint, face, or strong)
      final hasBiometric = availableBiometrics.contains(BiometricType.fingerprint) ||
                          availableBiometrics.contains(BiometricType.strong) ||
                          availableBiometrics.contains(BiometricType.face);
      print('Has biometric capability: $hasBiometric');
      
      if (!hasBiometric) {
        print('No suitable biometric found');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Silakan gunakan biometrik untuk login',
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      
      print('Authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      print('Error during authentication: ${e.toString()}');
      if (e.code == 'NotAvailable') {
        print('Biometric is not available on this device');
      } else if (e.code == 'NotEnrolled') {
        print('No biometrics are enrolled on this device');
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        print('Biometric authentication is locked out due to too many attempts');
      }
      return false;
    } catch (e) {
      print('Unexpected error during authentication: ${e.toString()}');
      return false;
    }
  }
}
