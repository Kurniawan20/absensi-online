import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import '../utils/storage_config.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final _storage = StorageConfig.secureStorage;

  // List to store listeners
  final List<VoidCallback> _listeners = [];

  // Method to add a listener
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Method to remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Method to notify all listeners
  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final prefs = await SharedPreferences.getInstance();
      final npp = prefs.getString('npp');
      if (npp == null) {
        throw Exception('NPP not found');
      }

      final now = DateTime.now();
      final response = await http.post(
        Uri.parse(ApiConstants.attendanceHistory),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "npp": npp,
          "year": now.year.toString(),
          "month": now.month.toString().padLeft(2, '0'),
        }),
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseStr = response.body.toString().replaceAll('""', '"');
        final responseData = jsonDecode(responseStr);

        // Handle API response format: { rcode, message, data }
        List<Map<String, dynamic>> records;
        if (responseData is Map<String, dynamic>) {
          if (responseData['rcode'] == '00') {
            final data = responseData['data'];
            // Handle new format: { data: { attendance: [...], statistics: {...} } }
            if (data is Map<String, dynamic> &&
                data.containsKey('attendance')) {
              records =
                  List<Map<String, dynamic>>.from(data['attendance'] ?? []);
            }
            // Handle legacy format: { data: [...] }
            else if (data is List) {
              records = List<Map<String, dynamic>>.from(data);
            } else {
              records = [];
            }
          } else {
            print('API returned error: ${responseData['message']}');
            return {
              'success': false,
              'check_in_time': '--:--',
              'check_out_time': '--:--',
            };
          }
        } else if (responseData is List) {
          // Fallback for legacy format (direct array)
          records = List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Unexpected response format');
          return {
            'success': false,
            'check_in_time': '--:--',
            'check_out_time': '--:--',
          };
        }

        final todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        print('Looking for record with date: $todayStr');
        print('Available records: $records');

        final todayRecord = records.firstWhere(
          (record) => record['tanggal'].toString() == todayStr,
          orElse: () => <String, dynamic>{
            'tanggal': todayStr,
            'jam_masuk': '--:--',
            'jam_keluar': '--:--',
          },
        );

        print('Today\'s record: $todayRecord');

        return {
          'success': true,
          'check_in_time': todayRecord['jam_masuk']?.toString() ?? '--:--',
          'check_out_time': todayRecord['jam_keluar']?.toString() ?? '--:--',
        };
      }

      return {
        'success': false,
        'check_in_time': '--:--',
        'check_out_time': '--:--',
      };
    } catch (e, stackTrace) {
      print('Error fetching attendance: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'check_in_time': '--:--',
        'check_out_time': '--:--',
      };
    }
  }

  Future<void> updateAttendanceTime(String type, String time) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert type to match the API response format
    if (type == 'absenmasuk') {
      prefs.setString('today_check_in', time);
      prefs.setString('jam_masuk', time); // Add this for compatibility
    } else if (type == 'absenpulang') {
      prefs.setString('today_check_out', time);
      prefs.setString('jam_keluar', time); // Add this for compatibility
    }

    // Notify listeners about the update
    notifyListeners();
  }
}
