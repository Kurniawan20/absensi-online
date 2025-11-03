import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' show IOClient;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import '../utils/storage_config.dart';

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

      // Log the request details
      print('Attempting login with:');
      print('NPP: $cleanNpp');
      print('Device ID: $cleanDeviceId');
      print('Platform: $platformName');

      final loginResponse = await _client
          .post(
            Uri.parse(ApiConstants.LOGIN),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Mobile-Presence-App/$platformName',
            },
            body: jsonEncode({
              'npp': cleanNpp,
              'password': password,
              'device_id': cleanDeviceId,
              'app_version': '1.0.0',
              'platform': platformName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Login request URL: ${ApiConstants.LOGIN}');
      print('Login request headers: ${jsonEncode({
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'User-Agent': 'Mobile-Presence-App',
      })}');
      print('Login request body: ${jsonEncode({
        'npp': cleanNpp,
        'password': '[REDACTED]',
        'device_id': cleanDeviceId,
        'app_version': '1.0.0',
        'platform': platformName,
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
        final message = loginData['message'] ?? loginData['error'] ?? 'Login gagal';
        print('Login error message: $message');
        return {
          'success': false,
          'message': message,
        };
      }

      final token = loginData['access_token'];
      await storage.write(key: 'auth_token', value: token);

      // Step 2: Office Data Request
      print(
          'Fetching office data for kode_kantor: ${loginData['kode_kantor']}');
      final kantorResponse = await _client
          .post(
            Uri.parse(ApiConstants.KANTOR),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode(
                {'kode_kantor': loginData['kode_kantor'], 'npp': email}),
          )
          .timeout(const Duration(seconds: 10));

      print('Office data response status code: ${kantorResponse.statusCode}');
      print('Office data response body: ${kantorResponse.body}');
      print('Office data response headers: ${kantorResponse.headers}');

      if (kantorResponse.statusCode != 200) {
        print(
            'Office data request failed with status: ${kantorResponse.statusCode}');
        return {
          'success': false,
          'error': 'Failed to get office data: ${kantorResponse.statusCode}',
          'response': kantorResponse.body,
        };
      }

      final kantorData = json.decode(kantorResponse.body);
      print('Parsed office data: $kantorData');

      // Check for error response
      if (kantorData['status'] == false || kantorData['rcode'] == '99') {
        print(
            'Office data request failed with status: ${kantorData['status']}, rcode: ${kantorData['rcode']}');
        return {
          'success': false,
          'error': kantorData['message'] ?? 'Failed to get office data',
          'details': kantorData,
        };
      }

      // Extract office data with null safety
      final officeData = kantorData['data'] ?? kantorData;
      print('Office data structure: $officeData');

      // Extract coordinates with detailed logging
      String? rawLatitude = officeData['latitude']?.toString();
      String? rawLongitude = officeData['longitude']?.toString();
      String? rawRadius = officeData['radius']?.toString();

      print(
          'Raw coordinates - Lat: $rawLatitude, Long: $rawLongitude, Radius: $rawRadius');

      // Convert office coordinates to double with null safety
      final officeLatitude = double.tryParse(rawLatitude ?? '0') ?? 0.0;
      final officeLongitude = double.tryParse(rawLongitude ?? '0') ?? 0.0;
      final officeRadius = double.tryParse(rawRadius ?? '0') ?? 0.0;

      print(
          'Converted coordinates - Lat: $officeLatitude, Long: $officeLongitude, Radius: $officeRadius');

      // Store user data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('npp', email),
        prefs.setString('nama', loginData['nama']),
        prefs.setString('token', token),
        prefs.setString('kode_kantor', loginData['kode_kantor']),
        prefs.setString('nama_kantor', loginData['nama_kantor']),
        prefs.setBool('is_login', true),
        prefs.setDouble('lat_kantor', officeLatitude),
        prefs.setDouble('long_kantor', officeLongitude),
        prefs.setDouble('radius', officeRadius),
        prefs.setString('device_id', deviceId),
      ]);

      return {
        'success': true,
        'token': token,
        'nama': loginData['nama'],
        'kode_kantor': loginData['kode_kantor'],
        'nama_kantor': loginData['nama_kantor'],
        'lat_kantor': officeLatitude,
        'long_kantor': officeLongitude,
        'radius': officeRadius,
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
    await prefs.remove('email');
    await prefs.remove('password');
    await _secureStorage.handleLogout();
  }

  void dispose() {
    _client.close();
  }
}
