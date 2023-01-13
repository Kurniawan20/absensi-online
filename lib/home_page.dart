import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:monitoring_project/screens/notification_api.dart';
import './screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';
import './screens/presence.dart';
import 'utils/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:get_mac/get_mac.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../widget/dialogs.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  static const String id = 'home_page';
  static const String expiryDate = "";

  @override
  _Homescreenstate createState() => _Homescreenstate();
}

class _Homescreenstate extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.green[700],
      ),body: Column(
        children: [
          SizedBox(
            width: 10,
            height: 10,
          ),
          Center(
            child:
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topLeft:Radius.circular(10),topRight: Radius.circular(10),bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10))
                  ),
                  child:
                    Row(
                      children: [

                      ],
                    )
                  // const SizedBox(
                  //   width: 370,
                  //   height: 120,
                  //   child: Text(''),
                  // ),
                )
          )

        ],
    ),
    );
  }
}
