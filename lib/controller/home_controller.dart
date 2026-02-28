import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:monitoring_project/Models/data_employee.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/io_client.dart';

import '../constants/api_constants.dart';
import '../utils/storage_config.dart';

class HomeController {
  SharedPreferences? preferences;
  late SharedPreferences _sharedPreferences;
  final storage = StorageConfig.secureStorage;

  Future<void> initializePreference() async {
    preferences = await SharedPreferences.getInstance();
  }

  Future<String?> getUsername() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    return _sharedPreferences.getString("npp");
  }

  Future<String?>? getNpp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? npp = prefs.getString('npp');
    return npp;
  }

  HttpClient createHttpClient() {
    HttpClient client = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    return client;
  }

  Future<List<DataEmployee>> fetchData() async {
    try {
      _sharedPreferences = await SharedPreferences.getInstance();
      print(_sharedPreferences.getString("npp"));
      String? npp = _sharedPreferences.getString("npp");
      var token = await storage.read(key: 'token');

      final httpClient = createHttpClient();
      final ioClient = IOClient(httpClient);

      final response = await ioClient
          // ignore: deprecated_member_use_from_same_package
          .get(Uri.parse('${ApiConstants.blogsLegacy}/$npp'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List jsonResponse;

        // Handle wrapped API response format: {rcode, message, data}
        if (responseData is Map<String, dynamic>) {
          if (responseData['rcode'] == '00' ||
              responseData['rcode'] == 'S' ||
              responseData['status'] == 'success') {
            jsonResponse = responseData['data'] ?? [];
          } else {
            // API returned error
            final message =
                responseData['message'] ?? 'Failed to fetch employee data';
            throw Exception(message);
          }
        } else if (responseData is List) {
          // Legacy: direct array response
          jsonResponse = responseData;
        } else {
          throw Exception('Unexpected response format');
        }

        return jsonResponse.map((data) => DataEmployee.fromJson(data)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw HttpException(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (_) {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException catch (e) {
      throw Exception('Connection timeout: $e');
    } on HttpException catch (e) {
      throw Exception('HTTP error: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
