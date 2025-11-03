import 'dart:convert';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../bloc/presence/presence_state.dart';
import '../utils/storage_config.dart';

class PresenceRepository {
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String deviceId,
    String? imageBase64,
  }) async {
    try {
      final storage = StorageConfig.secureStorage;
      final token = await storage.read(key: 'auth_token');
      
      print('\n=== Making attendance request (check-in) ===');
      print('URL: ${ApiConstants.BASE_URL}/absenmasuk');
      print('Headers: Authorization: Bearer ${token?.substring(0, min(10, token?.length ?? 0))}...');
      print('Body: {');
      print('  latitude: $latitude,');
      print('  longitude: $longitude,');
      print('  device_id: $deviceId');
      if (imageBase64 != null) print('  image: [base64 image data]');
      print('}');

      if (token == null) {
        throw Exception('Token not found for attendance request');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConstants.BASE_URL}/absenmasuk'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'device_id': deviceId,
              if (imageBase64 != null) 'image': imageBase64,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Attendance response status: ${response.statusCode}');
      print('Attendance response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return {
          'success': true,
          'message': data['message'],
          'checkInTime': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } catch (e) {
      print('Error during attendance: ${e.toString()}');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String deviceId,
    String? imageBase64,
  }) async {
    try {
      final storage = StorageConfig.secureStorage;
      final token = await storage.read(key: 'auth_token');
      
      print('\n=== Making attendance request (checkout) ===');
      print('URL: ${ApiConstants.BASE_URL}/absenpulang');
      print('Headers: Authorization: Bearer ${token?.substring(0, min(10, token?.length ?? 0))}...');
      print('Body: {');
      print('  latitude: $latitude,');
      print('  longitude: $longitude,');
      print('  device_id: $deviceId');
      if (imageBase64 != null) print('  image: [base64 image data]');
      print('}');

      if (token == null) {
        throw Exception('Token not found for attendance request');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConstants.BASE_URL}/absenpulang'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'device_id': deviceId,
              if (imageBase64 != null) 'image': imageBase64,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Attendance response status: ${response.statusCode}');
      print('Attendance response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['rcode'] == '00') {
        return {
          'success': true,
          'message': data['message'],
          'checkOutTime': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } catch (e) {
      print('Error during attendance: ${e.toString()}');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<Map<String, dynamic>> verifyLocation(
      double latitude, double longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final officeLatitude = prefs.getDouble('lat_kantor') ?? 0.0;
      final officeLongitude = prefs.getDouble('long_kantor') ?? 0.0;
      final allowedRadius = prefs.getDouble('radius') ?? 0.0;

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        officeLatitude,
        officeLongitude,
      );

      return {
        'success': true,
        'isWithinRadius': distance <= allowedRadius,
        'distance': distance,
      };
    } catch (e) {
      print('Error during location verification: ${e.toString()}');
      return {
        'success': false,
        'error': 'Failed to verify location: ${e.toString()}',
      };
    }
  }
}
