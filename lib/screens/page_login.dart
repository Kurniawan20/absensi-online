import 'dart:ffi';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:monitoring_project/screens/Apis.dart';
import 'package:monitoring_project/screens/home_page.dart';
import 'package:monitoring_project/main.dart';
import 'dart:convert';
import '../widget/dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:android_id/android_id.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class Login extends StatefulWidget {

  const Login({Key? key}) : super(key: key);
  static const String id = 'login';

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  @override
  void initState() {
    super.initState();
    _initAndroidId();
    getUserCurrentLocation();
    _getId();
    _passwordVisible = false;
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var  txtEditEmail = TextEditingController();
  var  txtEditPwd = TextEditingController();
  String token = "";
  String nama = "";
  String kode_kantor = "";
  String nama_kantor = "";
  double lat_kantor = 0;
  double long_kantor = 0;
  double radius = 0;
  String ket_bidang = "";
  String deviceId= "";
  bool _passwordVisible = false;

  Future<Position> getUserCurrentLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        _fetchDialogWarning(context, "Mohon izikan akses lokasi untuk menggunakan aplikasi ini");
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      permission = await Geolocator.requestPermission();
      _fetchDialogWarning(context, "Mohon izikan akses lokasi untuk menggunakan aplikasi ini");
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _fetchDialogWarning(BuildContext context, String message, [bool mounted = true]) async {
    // show the loading dialog
    showDialog(
      // The user CANNOT close this dialog  by pressing outsite it
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Gagal!',style: TextStyle(color: Colors.black),),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('OK',style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

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

  static const _androidIdPlugin = AndroidId();
  var _androidId = 'Unknown';

  Future<void> _initAndroidId() async {
    String androidId;
    try {
      androidId = await _androidIdPlugin.getId() ?? 'Unknown ID';
    } on PlatformException {
      androidId = 'Failed to get Android ID.';
    }

    if (!mounted) return;

    setState(() => _androidId = androidId);

    print("android id : "+androidId);
  }

  Future<String?> _getId() async {

    var deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {

      var iosDeviceInfo = await deviceInfo.iosInfo;
      _androidId = iosDeviceInfo.identifierForVendor!;

      return iosDeviceInfo.identifierForVendor; // unique ID on iOS

    } else if(Platform.isAndroid) {

      const _androidIdPlugin = AndroidId();
      final String? androidId = await _androidIdPlugin.getId();
      _androidId = _androidId;

      return androidId;
    }

  }

  Future<void> doLogin(npp, password) async {

    // var deviceiId = _getId();

    final GlobalKey<State> _keyLoader = GlobalKey<State>();
    Dialogs.loading(context, _keyLoader, "Proses...");

    // // ==> Perubahan
    // const _androidIdPlugin = AndroidId();
    // final String? androidId = await _androidIdPlugin.getId();
    // // <===
    //
    // print(
    //     Platform.isAndroid
    //         ? 'Android Device Info'
    //         : Platform.isIOS
    //         ? 'iOS Device Info'
    //         : ''
    // );

    try {

      //FETCH LOGIN
      final response = await http.post(

          Uri.parse(ApiConstants.BASE_URL+"/login"),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            "npp": npp,
            "password": password,
            "device_id": _androidId
          })
      ).timeout( const Duration(seconds: 10));

      print(jsonDecode(response.body));

      final output = jsonDecode(response.body);

      //FETCH KODE KANTOR
      if (output['rcode'] == "00") {

        final storage = const FlutterSecureStorage();
        await storage.write(key: 'token', value: output['access_token']);
        var token = await storage.read(key: 'token');
        final getResult = await http.post(

            Uri.parse(ApiConstants.BASE_URL+"/kantor"),
            headers: <String, String> {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode(<String, String>{
              'kode_kantor': output['kode_kantor'],
              "npp": npp
            })

        ).timeout( const Duration(seconds: 10));

        final output2 = jsonDecode(getResult.body);
        print(output2['ket_bidang']);
        print(output2['radius']);

        if(output['rcode'] == '00') {

          token = output['access_token'];
          nama = output['nama'];
          kode_kantor = output['kode_kantor'];
          nama_kantor = output['nama_kantor'];
          lat_kantor = double.parse(output2['latitude']) ;
          long_kantor = double.parse(output2['longitude']);
          radius = double.parse(output2['radius']);
          deviceId = _androidId;
          // ket_bidang = output['ket_bidang'];

          Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();

          if (output['message'] == 'authenticated') {
            saveSession(npp);
          }

        } else {

          Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
          Dialogs.popUp(context, output["message"].toString());
        }

      }else {

          Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
          Dialogs.popUp(context, output["message"].toString());
      }
    }

    on TimeoutException catch (e) {

      Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
      Dialogs.popUp(context, 'Timeout' );

    }}

  saveSession(String npp) async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    // Map<String, dynamic> payload = Jwt.parseJwt(token);
    // DateTime? expiryDate = Jwt.getExpiryDate(token);

    pref.setString("npp", npp);
    pref.setString("nama", nama);
    pref.setString("token", token);
    pref.setString("kode_kantor", kode_kantor);
    pref.setString("nama_kantor", nama_kantor);
    // pref.setString("expired", expiryDate.toString());
    pref.setBool("is_login", true);
    pref.setDouble("lat_kantor", lat_kantor);
    pref.setDouble("long_kantor", long_kantor);
    pref.setDouble("radius", radius);
    pref.setString("ket_bidang", ket_bidang);
    pref.setString("device_id", _androidId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => MyMain()),
    );
  }

  final textFieldFocusNode = FocusNode();
  bool _obscured = false;

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
      if (textFieldFocusNode.hasPrimaryFocus) return; // If focus is on text field, dont unfocus
      textFieldFocusNode.canRequestFocus = false;     // Prevents focus if tap on eye
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
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
                          children:  [
                            Image(image: AssetImage("assets/images/Logo_Bank_Aceh_Syariah.png"),height: 50),
                            SizedBox(height: 21.5),
                            /// LOGIN TEXT
                            Center(
                              child:
                              RichText(
                                text: TextSpan(
                                  // text: 'Hello ',
                                  style: TextStyle(fontSize: 19),
                                  children: <TextSpan>[
                                    TextSpan(text: 'HADIR BANK ACEH ', style: TextStyle(fontWeight: FontWeight.bold,color: Color.fromRGBO(1, 101, 65, 1))),
                                    // TextSpan(text: 'MOBILE',style: TextStyle(fontWeight: FontWeight.bold,color:Color.fromRGBO(1, 101, 65, 1))),
                                    // TextSpan(text: 'APLIKASI HADIR BANK ACEH',style: TextStyle(fontWeight: FontWeight.bold,color:Color.fromRGBO(1, 101, 65, 1))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            // color: Colors.white,
                            color: Color.fromRGBO(1, 101, 65, 1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child:
                            Column(
                              children: [
                                const SizedBox(height: 20),
                                /// Text Fields
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 15),
                                  width: MediaQuery.of(context).size.width,
                                  child:
                                  Column(

                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                          child: Text("NRK",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500)),
                                      ),
                                      Padding (
                                          padding: EdgeInsets.fromLTRB(10, 4, 10, 0),
                                          child: TextFormField(
                                            style: TextStyle(fontSize: 14),
                                            decoration: InputDecoration (
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                              hintText: '',
                                              fillColor: Colors.white,
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(11.0),
                                              ),
                                              focusedBorder:OutlineInputBorder(
                                                borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                                borderRadius: BorderRadius.circular(11.0),
                                              ),
                                              isCollapsed: false,
                                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                              prefixIcon: Icon(Icons.person),
                                                prefixIconColor: MaterialStateColor.resolveWith((states) =>
                                                states.contains(MaterialState.focused)
                                                    ? Colors.black
                                                    : Colors.grey)
                                            ),
                                            controller: txtEditEmail,
                                          ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                        child: Text("Password",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500)),
                                      ),
                                      Padding (
                                        padding: EdgeInsets.fromLTRB(10, 4, 10, 10),
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                                hintText: '',
                                                fillColor: Colors.white,
                                                filled: true,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(11.0),
                                                ),
                                                focusedBorder:OutlineInputBorder(
                                                  borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                                  borderRadius: BorderRadius.circular(11.0),
                                                ),
                                                isCollapsed: false,
                                                hintStyle: TextStyle(fontSize: 14, color: Colors.black),
                                                prefixIcon: Icon(Icons.lock_rounded, size: 22,),
                                                prefixIconColor: Colors.grey,
                                                suffixIcon: IconButton(
                                                  color: Colors.grey.withOpacity(0.5),
                                                    icon: Icon(
                                                      size: 22,
                                                      _passwordVisible
                                                          ? Icons.visibility
                                                          : Icons.visibility_off,

                                                    ),
                                                  onPressed: () {
                                                      setState(() {
                                                        _passwordVisible = !_passwordVisible;
                                                      });
                                                  },
                                                )
                                            ),
                                            controller: txtEditPwd,
                                            onSaved: (String? val) {
                                              txtEditPwd.text = val!;
                                            },
                                            obscureText: !_passwordVisible,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            validator: (String? arg) {
                                              if (arg == null || arg.isEmpty) {
                                                return 'Password tidak boleh kosong!';
                                              } else {
                                                return null;
                                              }
                                            },
                                          ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 60),
                                /// LOGIN BUTTON
                                Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 25),
                                    height: 50,
                                    width: MediaQuery.of(context).size.width,
                                    child:
                                      ElevatedButton(
                                        child: const Text('Log in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,color:Color.fromRGBO(1, 101, 65, 1)),),
                                        style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.0),
                                                )
                                        ),
                                        ),
                                        onPressed: () => {
                                          _validateInputs(),
                                        } ,
                                      )
                                ),
                                const SizedBox(height: 50),
                                Text(
                                  "Version 1.0",
                                  style: TextStyle(color: Colors.white,fontSize: 12),
                                )
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
