import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/io_client.dart' show IOClient;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import '../services/device_info_service.dart';
import '../services/avatar_service.dart';
import '../models/office_location.dart';
import '../utils/storage_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginRepository {
  final storage = StorageConfig.secureStorage;
  late final IOClient _client;
  final _secureStorage = SecureStorageService();

  LoginRepository() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 10);
    _client = IOClient(httpClient);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      // Clean and format the input data
      final cleanNpp = email.trim();
      final cleanDeviceId = deviceId.trim();

      // Detect platform correctly
      final platformName = Platform.isIOS ? 'ios' : 'android';

      // Get device info for backend logging
      final deviceInfoService = DeviceInfoService();
      final deviceInfo = await deviceInfoService.getDeviceInfo();

      // Log the request details
      print('Attempting login with:');
      print('NPP: $cleanNpp');
      print('Device ID: $cleanDeviceId');
      print('Platform: $platformName');
      print('Device Info: $deviceInfo');

      final loginResponse = await _client
          .post(
            Uri.parse(ApiConstants.login),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Mobile-Presence-App/$platformName',
            },
            body: jsonEncode({
              'npp': cleanNpp,
              'password': password,
              'device_id': cleanDeviceId,
              'device_info': deviceInfo,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Login request URL: ${ApiConstants.login}');
      print('Login request headers: ${jsonEncode({
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
            'User-Agent': 'Mobile-Presence-App',
          })}');
      print('Login request body: ${jsonEncode({
            'npp': cleanNpp,
            'password': '[REDACTED]',
            'device_id': cleanDeviceId,
            'device_info': deviceInfo,
          })}');
      print('Login response status code: ${loginResponse.statusCode}');
      print('Login response headers: ${loginResponse.headers}');
      print('Login response body: ${loginResponse.body}');

      if (loginResponse.statusCode != 200) {
        Map<String, dynamic> errorBody;
        try {
          errorBody = jsonDecode(loginResponse.body);
          print('Login error response: $errorBody');
        } catch (e) {
          print('Failed to parse error response: $e');
          return {
            'success': false,
            'message': 'Gagal terhubung ke server',
          };
        }
        return {
          'success': false,
          'message': errorBody['message'] ?? 'Login gagal',
          'details': errorBody,
        };
      }

      Map<String, dynamic> loginData;
      try {
        loginData = json.decode(loginResponse.body);
        print('Parsed login data: $loginData');
      } catch (e) {
        print('Failed to parse login response: $e');
        return {
          'success': false,
          'message': 'Format response tidak valid',
        };
      }

      if (loginData['rcode'] != "00") {
        print('Login failed with rcode: ${loginData['rcode']}');
        final message =
            loginData['message'] ?? loginData['error'] ?? 'Login gagal';
        print('Login error message: $message');
        return {
          'success': false,
          'message': message,
        };
      }

      final token = loginData['access_token'];
      await storage.write(key: 'auth_token', value: token);

      // Parse locations array dari login response
      final List<OfficeLocation> locations = [];
      if (loginData['locations'] != null && loginData['locations'] is List) {
        for (var loc in loginData['locations']) {
          try {
            locations.add(OfficeLocation.fromJson(loc));
          } catch (e) {
            print('Error parsing location: $e');
          }
        }
      }

      // Validasi: locations harus ada minimal 1
      if (locations.isEmpty) {
        print('Error: No office locations found in login response');
        return {
          'success': false,
          'message':
              'Data lokasi kantor tidak ditemukan. Silakan hubungi administrator.',
        };
      }

      print('Loaded ${locations.length} office location(s):');
      for (var loc in locations) {
        print(
            '  - ${loc.nama}: (${loc.latitude}, ${loc.longitude}), radius: ${loc.radius}m');
      }

      // Store user data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Force reload to ensure we have fresh state before writing
      await prefs.reload();

      // Simpan gender dan set avatar otomatis berdasarkan gender
      // Gender: 01 = male (pria), 02 = female (wanita)
      final gender = loginData['gender']?.toString() ?? '01';
      final avatarPath = gender == '02'
          ? AvatarService.getAvatarPathById('female_2')
          : AvatarService.getAvatarPathById('male_2');

      await Future.wait([
        prefs.setString('npp', email),
        prefs.setString('nama', loginData['nama']),
        prefs.setString('token', token),
        prefs.setString('kode_kantor', loginData['kode_kantor']),
        prefs.setString('nama_kantor', loginData['nama_kantor']),
        prefs.setString('gender', gender),
        prefs.setBool('is_login', true),
        prefs.setString('device_id', deviceId),
        // Simpan locations sebagai JSON string
        prefs.setString(
            'office_locations', OfficeLocation.toJsonString(locations)),
      ]);

      // Set avatar otomatis berdasarkan gender
      final avatarService = AvatarService();
      await avatarService.setSelectedAvatar(avatarPath);

      print(
          'Login data saved successfully with ${locations.length} location(s)');

      return {
        'success': true,
        'token': token,
        'nama': loginData['nama'],
        'kode_kantor': loginData['kode_kantor'],
        'nama_kantor': loginData['nama_kantor'],
        'locations': locations,
        'ket_bidang': loginData['ket_bidang'] ?? '',
      };
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection',
      };
    } on HandshakeException catch (e) {
      print('SSL error: $e');
      return {
        'success': false,
        'error': 'SSL error: Could not establish secure connection to server',
      };
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      return {
        'success': false,
        'error': 'Connection timeout: Server is not responding',
      };
    } catch (e) {
      print('Unexpected error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_login') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Unregister FCM token before clearing data
    await _unregisterFcmToken();

    // Unsubscribe from broadcast topic
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
      print('Unsubscribed from "all" topic');
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }

    // Clear device info cache
    DeviceInfoService().clearCache();

    // Clear auth data
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('npp');
    await prefs.remove('nama');
    await prefs.remove('token');
    await prefs.setBool('is_login', false);

    // Clear office data - PENTING: agar data baru di-load saat login ulang
    await prefs.remove('kode_kantor');
    await prefs.remove('nama_kantor');
    await prefs.remove('office_locations');
    await prefs.remove('device_id');
    await prefs.remove('gender');

    await _secureStorage.handleLogout();
  }

  /// Unregister FCM token from backend
  Future<void> _unregisterFcmToken() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (token == null || fcmToken == null) {
        print('FCM Unregister skipped: token or fcmToken is null');
        return;
      }

      print('=== Unregistering FCM Token ===');
      print('FCM Token: ${fcmToken.substring(0, 20)}...');

      final response = await _client
          .post(
            Uri.parse(ApiConstants.fcmUnregister),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('FCM token unregistered successfully');
      } else {
        print('FCM unregister failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Don't block logout if FCM unregistration fails
      print('FCM Unregister error (non-blocking): $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
