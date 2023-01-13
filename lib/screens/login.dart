import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:monitoring_project/main.dart';
import 'dart:convert';
import '../widget/dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_mac/get_mac.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:android_id/android_id.dart';

class Login extends StatefulWidget {

  const Login({Key? key}) : super(key: key);
  static const String id = 'login';

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var  txtEditEmail = TextEditingController();
  var  txtEditPwd = TextEditingController();
  String token = "";
  String nama = "";
  String kode_kantor = "";

  void fireToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void fireToast2(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green.shade900,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      //If all data are correct then save data to out variables
      _formKey.currentState!.save();
      doLogin(txtEditEmail.text, txtEditPwd.text);
    }
  }

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _initAndroidId();
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {

        if (Platform.isAndroid) {
          deviceData =
              _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        } else if (Platform.isIOS) {
          deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'displaySizeInches':
      ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayWidthInches': build.displayMetrics.widthInches,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayHeightInches': build.displayMetrics.heightInches,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
    };

  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  String _deviceMAC = 'Click the button.';

  Future<void> initMacAddress() async {
    String macAddress;
    
    try {
    macAddress = await GetMac.macAddress;
    } on PlatformException {
    macAddress = 'Error getting the MAC address.';
    }
    
    setState(() {
    _deviceMAC = macAddress;
    });

    print("maccccccc" + _deviceMAC + macAddress);
  }

  static const _androidIdPlugin = AndroidId();
  var _androidId = 'Unknown';

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initAndroidId() async {
    String androidId;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      androidId = await _androidIdPlugin.getId() ?? 'Unknown ID';
    } on PlatformException {
      androidId = 'Failed to get Android ID.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() => _androidId = androidId);

    print("android id : "+androidId);
  }

  // Future<String?> _getId() async {
  //   var deviceInfo = DeviceInfoPlugin();
  //   if (Platform.isIOS) { // import 'dart:io'
  //     var iosDeviceInfo = await deviceInfo.iosInfo;
  //     return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  //   } else if(Platform.isAndroid) {
  //     var androidDeviceInfo = await deviceInfo.androidInfo;
  //     return androidDeviceInfo.androidId; // unique ID on Android
  //   }
  // }
  
  Future<void> doLogin(npp, password) async {

    final GlobalKey<State> _keyLoader = GlobalKey<State>();
    Dialogs.loading(context, _keyLoader, "Proses...");

    const _androidIdPlugin = AndroidId();
    final String? androidId = await _androidIdPlugin.getId();

    print(androidId);
    // _deviceData.keys.map(
    //         (String property){
    //           return print(
    //             'test-----------------' +
    //             '${_deviceData[property]}',
    //           );
    //         }
    // );

    // print("Device id" + _deviceData['id']);
    // print("Device brand" + _deviceData['brand']);
    // print("Device codename" + _deviceData['version.codename']);
    // print("Device device" + _deviceData['build.device']);

    print(
        Platform.isAndroid
            ? 'Android Device Info'
            : Platform.isIOS
            ? 'iOS Device Info'
            : ''
    );

    try {

      final response = await http.post(
          Uri.parse("http://192.168.100.16/mobile-auth-api/public/api/login"),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            "npp": npp,
            "password": password,
            "mac": _androidId
          }));

      final output = jsonDecode(response.body);

      print(response.body.toString());


      if (response.statusCode == 200) {

        if(output['rcode'] == '00') {

          token = output['access_token'];
          nama = output['user']['nama'];
          kode_kantor = output['kode_kantor'];

          Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();

          if (output['message'] == 'authenticated') {
            saveSession(npp);
          }

        }else{

          Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                  output['message'].toString(),
                  style: const TextStyle(fontSize: 16),
                )
            ),
          );
        }
      }

      else {

        Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                output['message'].toString(),
                style: const TextStyle(fontSize: 16),
              )
          ),
        );
      }
    } catch (e) {
      Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
      Dialogs.popUp(context, '$e');
    }
  }

  saveSession(String npp) async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    Map<String, dynamic> payload = Jwt.parseJwt(token);
    DateTime? expiryDate = Jwt.getExpiryDate(token);

    pref.setString("npp", npp);
    pref.setString("nama", nama);
    pref.setString("token", token);
    pref.setString("kode_kantor", kode_kantor);
    pref.setString("expired", expiryDate.toString());
    pref.setBool("is_login", true);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MyMain(),
      ),
          (route) => false,
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green,
                  Colors.green.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.centerRight,
              ),
            ),

            child: Form(
                key: _formKey,
                child: Column(
                    children: [
                      /// Login & Welcome back
                      Container(
                        height: 210,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            // Icon(Icons.confirmation_num_sharp),
                            // Text('Authentication Manajemen', style: TextStyle(color: Colors.white, fontSize: 27.5)),
                            // Image.asset("assets/images/Logo_Bank_Aceh_Syariah.png"),
                            Image(image: AssetImage("assets/images/Logo_Bank_Aceh_Syariah.png"),height: 40),
                            SizedBox(height: 20.5),
                            /// LOGIN TEXT
                            Text('Absensi Online', style: TextStyle(color: Colors.white, fontSize: 19.5),textAlign: TextAlign.center,),
                            SizedBox(height: 5.5),
                            /// WELCOME
                            Text('Silahkan Login', style: TextStyle(color: Colors.white, fontSize: 15),textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 60),
                                /// Text Fields
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 25),
                                  height: 120,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 10,
                                            offset: const Offset(0, 10)
                                        ),
                                      ]
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Flexible(
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14),
                                            decoration: InputDecoration (
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                              border: InputBorder.none,
                                              hintText: 'NPP',
                                              isCollapsed: false,
                                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            controller: txtEditEmail,
                                            onSaved: (String? val) {
                                              txtEditEmail.text = val!;
                                            },
                                            validator: (String? arg) {
                                              if (arg == null || arg.isEmpty) {
                                                return 'NPP harus diisi';
                                              } else {
                                                return null;
                                              }
                                            },
                                          ),
                                      ),
                                      Divider(color: Colors.black54, height: 1),
                                      Flexible(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                              border: InputBorder.none,
                                              hintText: 'Password',
                                              isCollapsed: false,
                                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            controller: txtEditPwd,
                                            onSaved: (String? val) {
                                              txtEditPwd.text = val!;
                                            },
                                            obscureText: true,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            validator: (String? arg) {
                                              if (arg == null || arg.isEmpty) {
                                                return 'Password harus diisi';
                                              } else {
                                                return null;
                                              }
                                            },
                                          ),
                                      )
                                      /// NPP
                                      // TextFormField(
                                      //     style: TextStyle(fontSize: 1),
                                      //     decoration: InputDecoration (
                                      //       contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                      //       border: InputBorder.none,
                                      //       hintText: 'NPP',
                                      //       isCollapsed: false,
                                      //       hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                      //     ),
                                      //     controller: txtEditEmail,
                                      //     onSaved: (String? val) {
                                      //       txtEditEmail.text = val!;
                                      //     },
                                      //     validator: (String? arg) {
                                      //       if (arg == null || arg.isEmpty) {
                                      //         return 'NPP harus diisi';
                                      //       } else {
                                      //         return null;
                                      //       }
                                      //     },
                                      // ),
                                      // Divider(color: Colors.black54, height: 1),
                                      // /// PASSWORD
                                      // TextFormField(
                                      //     decoration: InputDecoration(
                                      //       contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                      //       border: InputBorder.none,
                                      //       hintText: 'Password',
                                      //       isCollapsed: false,
                                      //       hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                      //     ),
                                      //     controller: txtEditPwd,
                                      //     onSaved: (String? val) {
                                      //       txtEditPwd.text = val!;
                                      //     },
                                      //     obscureText: true,
                                      //     enableSuggestions: false,
                                      //     autocorrect: false,
                                      //     validator: (String? arg) {
                                      //     if (arg == null || arg.isEmpty) {
                                      //       return 'Password harus diisi';
                                      //     } else {
                                      //       return null;
                                      //     }
                                      //   },
                                      // ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 35),
                                /// LOGIN BUTTON
                                MaterialButton(
                                  onPressed: () => {
                                    _validateInputs(),
                                    initMacAddress(),
                                  } ,
                                  height: 45,
                                  minWidth: 240,
                                  child: const Text('Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                                  textColor: Colors.white,
                                  color: Colors.green.shade700,
                                  shape: const StadiumBorder(),
                                ),
                                const SizedBox(height: 25),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ])
              )
          )
      );
   }
}
