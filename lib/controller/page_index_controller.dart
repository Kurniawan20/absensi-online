import 'dart:convert';
import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// import 'package:presensi/app/routes/app_pages.dart';
import 'package:monitoring_project/routes/app_pages.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
// import 'package:safe_device/safe_device.dart';

class PageIndexController extends GetxController {
  RxInt pageIndex = 0.obs;
  // RxBool isLoading = false.obs;
  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;

    void changePage(int i) async {
    // final User user = auth.currentUser!;
    // final uid = user.uid;

    // API DateTime GMT +07:00
    var myResponse = await http.get(
      Uri.parse(
          "https://timeapi.io/api/Time/current/zone?timeZone=Asia/Jakarta"),
    );

    Map<String, dynamic> data = json.decode(myResponse.body);

    // print(data);
    // print(myResponse.body);

    var dateTimeAPI = data['dateTime'];

    DateTime dateTimeGMT = DateTime.parse(dateTimeAPI);

    print(dateTimeGMT);

    // API DateTime GMT +07:00 - End

    String hariIni = DateFormat("EEE").format(dateTimeGMT);
    print(hariIni);
    String tanggalHariIni = DateFormat("d").format(dateTimeGMT);
    print(tanggalHariIni);

    // final nipSession = await firestore.collection("user").doc(uid).get();

    pageIndex.value = i;
    switch (i) {
      case 1:
        pageIndex.value = i;
        Get.offAllNamed(Routes.PRESENCE);
        break;
      case 2:
        pageIndex.value = i;
        Get.offAllNamed(Routes.HOME);
        break;
      // case 3:
      //   pageIndex.value = i;
      //   Get.offAllNamed(Routes.DINASLUAR);
      //   break;
      // case 4:
      //   pageIndex.value = i;
      //   Get.offAllNamed(Routes.PROFILE);
      //   break;
      default:
        pageIndex.value = i;
        Get.offAllNamed(Routes.HOME);
    }
  }
}
