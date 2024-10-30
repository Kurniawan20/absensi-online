import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:monitoring_project/Models/DataEmployee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../screens/Apis.dart';
import '../screens/page_login.dart';


class HomeController {

  SharedPreferences? preferences;
  late SharedPreferences _sharedPreferences;
  final storage = const FlutterSecureStorage();

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

    //Return String
    String? npp = prefs.getString('npp');

    return npp;
  }

  Future<List<DataEmpoyee>> fetchData() async {

    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    String? npp = _sharedPreferences.getString("npp");
    var token = await storage.read(key: 'token');

    final response = await http.get(
        Uri.parse(ApiConstants.BASE_URL+"/getblog/${npp}"),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        }
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => new DataEmpoyee.fromJson(data)).toList();
    } else {
      throw Exception('Unexpected error occured!');
    }
  }
}