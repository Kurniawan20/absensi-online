import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:monitoring_project/Models/DataEmployee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../screens/Apis.dart';
import '../utils/storage_config.dart';

class HomeController {
  SharedPreferences? preferences;
  late SharedPreferences _sharedPreferences;
  final storage = StorageConfig.secureStorage;

  Future<void> initializePreference() async {
    this.preferences = await SharedPreferences.getInstance();
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getUsername() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    return _sharedPreferences.getString("npp");
  }

  getNpp() async {
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
          .get(Uri.parse(ApiConstants.BASE_URL + "/getblog/${npp}"), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((data) => DataEmployee.fromJson(data))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw HttpException(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (e) {
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
