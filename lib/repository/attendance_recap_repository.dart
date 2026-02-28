import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/io_client.dart' show IOClient;
import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class AttendanceRecapRepository {
  late final IOClient _client;
  final SecureStorage _secureStorage;

  AttendanceRecapRepository({
    SecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorage() {
    final httpClient = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 10);
    _client = IOClient(httpClient);
  }

  Future<Map<String, dynamic>> getAttendanceHistory({
    required String npp,
    required int year,
    required int month,
  }) async {
    try {
      print('Fetching attendance history for NPP: $npp, Year: $year, Month: $month');
      final token = await _secureStorage.getToken();
      
      if (token == null || token.isEmpty) {
        print('Token not found');
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final url = Uri.parse(ApiConstants.attendanceHistory);
      print('Requesting URL: $url');
      
      final requestBody = {
        "npp": npp,
        "year": year.toString(),
        "month": month.toString().padLeft(2, '0'),
        "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      };
      print('Request body: $requestBody');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle API response format: { rcode, message, data }
        if (responseData is Map<String, dynamic>) {
          if (responseData['rcode'] == '00') {
            final List<dynamic> jsonList = responseData['data'] ?? [];
            print('Parsed JSON list length: ${jsonList.length}');
            print('First record: ${jsonList.isNotEmpty ? jsonList.first : "No records"}');
            
            // Debug: Print all dates in the response
            if (jsonList.isNotEmpty) {
              print('All dates in response:');
              for (int i = 0; i < jsonList.length && i < 5; i++) {
                final record = jsonList[i];
                print('  Record $i: ${record['tanggal']} - ${record['jam_masuk']} - ${record['jam_keluar']}');
              }
            }
            
            return {'success': true, 'records': jsonList};
          } else {
            print('API returned error rcode: ${responseData['rcode']}');
            return {
              'success': false,
              'error': responseData['message'] ?? 'Failed to load attendance history',
            };
          }
        } else if (responseData is List) {
          // Fallback: jika API langsung return array (backward compatibility)
          print('Response is direct array (legacy format), length: ${responseData.length}');
          return {'success': true, 'records': responseData};
        }
        
        print('Unexpected response format: ${responseData.runtimeType}');
        return {'success': false, 'error': 'Unexpected response format'};
      } else {
        print('Request failed with status: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to load attendance history (${response.statusCode})',
          'body': response.body,
        };
      }
    } on TimeoutException {
      print('Connection timeout');
      return {
        'success': false,
        'error': 'Connection timeout: Server is not responding',
      };
    } on HandshakeException catch (e) {
      print('SSL/TLS handshake error: $e');
      return {
        'success': false,
        'error': 'SSL error: Could not establish secure connection to server',
      };
    } on SocketException catch (e) {
      print('Network connection error: $e');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection',
      };
    } catch (e, stackTrace) {
      print('Unexpected error: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> generateAttendanceReport({
    required String npp,
    required int year,
    required int month,
    required String reportType,
  }) async {
    try {
      final token = await _secureStorage.getToken();
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final url = Uri.parse(ApiConstants.generateReport);
      print('Requesting URL: $url');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode({
          'npp': npp,
          'year': year,
          'month': month,
          'report_type': reportType,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['report_url'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to generate report (${response.statusCode})',
          'body': response.body,
        };
      }
    } on TimeoutException {
      print('Connection timeout');
      return {
        'success': false,
        'error': 'Connection timeout: Server is not responding',
      };
    } on HandshakeException catch (e) {
      print('SSL/TLS handshake error: $e');
      return {
        'success': false,
        'error': 'SSL error: Could not establish secure connection to server',
      };
    } on SocketException catch (e) {
      print('Network connection error: $e');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection',
      };
    } catch (e, stackTrace) {
      print('Error in generateAttendanceReport: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance({required String npp}) async {
    try {
      final now = DateTime.now();
      final response = await getAttendanceHistory(
        npp: npp,
        year: now.year,
        month: now.month,
      );

      if (response['success'] == true && response['records'] != null) {
        final List<dynamic> attendanceList = response['records'];
        final today = DateTime.now();
        final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        
        final todayAttendance = attendanceList.firstWhere(
          (record) => record['tanggal'] == todayStr,
          orElse: () => null,
        );

        if (todayAttendance != null) {
          return {
            'success': true,
            'data': {
              'jam_masuk': todayAttendance['jam_masuk'],
              'jam_keluar': todayAttendance['jam_keluar'],
            },
          };
        }
      }

      return {
        'success': false,
        'error': 'No attendance data found for today',
      };
    } catch (e) {
      print('Error getting today attendance: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
