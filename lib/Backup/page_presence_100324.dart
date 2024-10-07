// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:device_info/device_info.dart';
// import 'package:fluentui_system_icons/fluentui_system_icons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:monitoring_project/screens/Apis.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../screens/page_login.dart';
// import '../page_login.dart';
// import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
// import 'package:quickalert/quickalert.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
//
// void main() => runApp(const Presence());
//
// class Presence extends StatefulWidget {
//   const Presence({Key? key}) : super(key: key);
//
//   @override
//   _PresenceState createState() => _PresenceState();
// }
//
// class _PresenceState extends State<Presence> {
//
//   bool _isMockLocation = false;
//   bool? _jailbroken;
//   bool? _developerMode;
//
//   SharedPreferences? preferences;
//   Timer? timer;
//   double latKantor = 0;
//   double longKantor = 0;
//   double radius = 0;
//   double zoomVar = 17;
//
//   double latKantor2 = 5.543605637891148;
//   double longKantor2 = 95.32992029020498;
//   static LatLng _initialPosition = LatLng(5.543605637891148, 95.32992029020498);
//
//   bool isJailBroken = false;
//   bool canMockLocation = false;
//   bool isRealDevice = true;
//   bool isOnExternalStorage = false;
//   bool isSafeDevice = false;
//   bool isDevelopmentModeEnable = false;
//   LatLng currentLatLng = LatLng(5.543605637891148, 95.32992029020498) ;
//
//   void initState(){
//     super.initState();
//     // initPlatformState();
//
//     getUserCurrentLocation();
//     initializePreference().then((result) {
//       setState(() {
//       });
//     });
//
//     Geolocator.getCurrentPosition().then((currLocation){
//       setState((){
//         currentLatLng = new LatLng(currLocation.latitude, currLocation.longitude);
//       });
//     });
//
//     print(currentLatLng);
//   }
//
//   Future<void> initializePreference() async {
//     this.preferences = await SharedPreferences.getInstance();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     latKantor = prefs.getDouble("lat_kantor")!;
//     longKantor = prefs.getDouble("long_kantor")!;
//     radius = prefs.getDouble("radius")!;
//
//     latKantor2 = prefs.getDouble("lat_kantor")!;
//     longKantor2 = prefs.getDouble("long_kantor")!;
//
//     setState(() {
//     });
//   }
//
//   Completer<GoogleMapController> _controller = Completer();
//
//   Future<Position> getUserCurrentLocation() async {
//
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _fetchDialogWarning(context, "Mohon izikan akses lokasi untuk melakukan absensi");
//         return Future.error('Location permissions are denied');
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//       _fetchDialogWarning(context, "Mohon izikan akses lokasi untuk melakukan absensi");
//       return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//     return await Geolocator.getCurrentPosition();
//   }
//
//   late GoogleMapController mapController;
//   GeolocatorPlatform _geo = new PresenceGeo( );
//   bool _inRadius = true;
//
//
//
//   void _checkRadius(String absenType) async {
//
//       getUserCurrentLocation().then((value) async {
//
//       final double distance = _geo.distanceBetween(
//         latKantor, longKantor,
//         value.latitude,
//         value.longitude,
//       );
//
//       setState(() {
//         this._inRadius = distance < radius;
//       });
//
//       _absen(value.latitude, value.longitude, absenType);
//
//     });
//   }
//
//   Set<Circle> circles = Set.from([Circle(
//       circleId: CircleId("2343"),
//       center: LatLng(5.543577914626673, 95.31220741678517),
//       radius: 100,
//       fillColor: Colors.orange.shade100.withOpacity(0.5),
//       strokeColor:  Colors.orange.shade100.withOpacity(0.1)
//   )]);
//
//   final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
//     onPrimary: Colors.white,
//     primary: Colors.blueAccent[300],
//     minimumSize: Size(10, 36),
//
//     padding: EdgeInsets.symmetric(horizontal: 10),
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(2)),
//     ),
//   );
//
//   void _fetchData(BuildContext context, [bool mounted = true]) async {
//     QuickAlert.show(
//       barrierDismissible: false,
//       context: context,
//       type: QuickAlertType.loading,
//       title: 'Mohon Tunggu',
//       text:  'Sedang memproses absensi..',
//
//     );
//   }
//
//   void _fetchDialog(BuildContext context, String message, [bool mounted = true]) async {
//     // show the loading dialog
//     showDialog(
//       // The user CANNOT close this dialog  by pressing outsite it
//         barrierDismissible: false,
//         context: context,
//         builder: (BuildContext context) => AlertDialog(
//           backgroundColor: Colors.white,
//             title: const Text('Berhasil',style: TextStyle(color: Colors.black87),),
//             content: Text(message),
//             actions: <Widget>[
//               // ElevatedButton(
//               //   style: ElevatedButton.styleFrom(
//               //     backgroundColor: Color.fromRGBO(1, 101, 65, 1),
//               //     foregroundColor: Colors.white,
//               //     padding: const EdgeInsets.all(10.0),
//               //     textStyle: const TextStyle(fontSize: 10),
//               //   ),
//               //   onPressed: () {
//               //     // Action to perform when button is pressed
//               //   },
//               //   child: const Text('Oke'),
//               // ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, 'OK'),
//                 child: const Text('OK',style: TextStyle(color: Colors.black87)),
//               ),
//             ],
//           ),
//     );
//   }
//
//   void _fetchDialogWarning(BuildContext context, String message, [bool mounted = true]) async {
//     // show the loading dialog
//     // showDialog(
//     //   // The user CANNOT close this dialog  by pressing outsite it
//     //   barrierDismissible: false,
//     //   context: context,
//     //   builder: (BuildContext context) => AlertDialog(
//     //     // backgroundColor: Colors.yellow,
//     //     title: const Text('Gagal!',style: TextStyle(color: Colors.black),),
//     //     content: Text(message),
//     //     actions: <Widget>[
//     //       TextButton(
//     //         onPressed: () => Navigator.pop(context, 'OK'),
//     //         child: const Text('OK',style: TextStyle(color: Colors.black)),
//     //       ),
//     //     ],
//     //   ),
//     // );
//
//     QuickAlert.show(
//       context: context,
//       type: QuickAlertType.error,
//       title: "Oops...",
//       text: message,
//       confirmBtnColor : Color.fromRGBO(1, 101, 65, 1),
//       confirmBtnText: 'Oke',
//     );
//   }
//
//   void _konfirmasiAbsenPulang(BuildContext context, String message, [bool mounted = true]) async {
//     // show the loading dialog
//     showDialog(
//       // The user CANNOT close this dialog  by pressing outsite it
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: const Text('Konfirmasi Absensi',style: TextStyle(color: Colors.black,fontWeight:FontWeight.bold),),
//         content: Text("Apakah anda yakin akan melakukan absen pulang?"),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () => Navigator.pop(context, 'Batal'),
//             child: const Text('Batal',style: TextStyle(color: Colors.black,fontSize: 12)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color.fromRGBO(1, 101, 65, 1),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.all(10.0),
//               textStyle: const TextStyle(fontSize: 10),
//             ),
//             onPressed: () {
//               Navigator.of(context,rootNavigator: true).pop(context);
//               _checkRadius('absenpulang');
//               _fetchData(context);
//             },
//             child: const Text('Pulang'),
//           ),
//         ],
//       ),
//     );
//
//   }
//
//   Future<String> _absen(double lat, double long, String absenType) async {
//
//     final prefs = await SharedPreferences.getInstance();
//     final branch_id = prefs.getString("kode_kantor").toString();
//     final nrk = prefs.getString("npp");
//     final _deviceId = prefs.getString("device_id");
//
//     bool jailbroken;
//     bool developerMode;
//
//       // if (Platform.isAndroid) {
//       //
//       //   AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
//       //
//       // } else {
//       //
//       //   IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
//       //
//       // }
//
//     var deviceInfo = DeviceInfoPlugin();
//     bool isPhysicalDevice = false;
//
//     if (Platform.isIOS) {
//
//       var iosDeviceInfo = await deviceInfo.iosInfo;
//       isPhysicalDevice = iosDeviceInfo.isPhysicalDevice!;
//
//     } else if(Platform.isAndroid) {
//
//       var androidDeviceInfo = await deviceInfo.androidInfo;
//       isPhysicalDevice = androidDeviceInfo.isPhysicalDevice!;
//
//     }
//
//     try {
//       jailbroken = await FlutterJailbreakDetection.jailbroken;
//       developerMode = await FlutterJailbreakDetection.developerMode;
//     } on PlatformException {
//       jailbroken = true;
//       developerMode = true;
//     }
//
//     _jailbroken = jailbroken;
//     _developerMode = developerMode;
//     print("DEVELOPER MODE ${_developerMode}");
//     print("JAILBREAK MODE ${_jailbroken}");
//
//     if(_developerMode == false) {
//
//       var message = "Mohon matikan developer mode anda!";
//
//       Navigator.of(context,rootNavigator: true).pop(context);
//
//       QuickAlert.show(
//         context: context,
//         type: QuickAlertType.warning,
//         title: "Warning",
//         text: message,
//         confirmBtnColor : Color.fromRGBO(1, 101, 65, 1),
//         confirmBtnText: 'Oke',
//       );
//
//       return "absen gagal";
//     }
//
//     else if(isPhysicalDevice == true) {
//
//       var message = "Anda terdeteksi menggunakan emulator!";
//
//       Navigator.of(context,rootNavigator: true).pop(context);
//
//       QuickAlert.show(
//         context: context,
//         type: QuickAlertType.warning,
//         title: "Warning",
//         text: message,
//         confirmBtnColor : Color.fromRGBO(1, 101, 65, 1),
//         confirmBtnText: 'Oke',
//       );
//
//       return "absen gagal";
//     }
//
//     try {
//
//       final storage = const FlutterSecureStorage();
//       var token = await storage.read(key: 'token');
//
//       final getResult = await http.post(
//           Uri.parse(ApiConstants.BASE_URL+"/checksession"),
//           headers: <String, String> {
//             'Content-Type': 'application/json; charset=UTF-8',
//             'Authorization': 'Bearer $token'
//           },
//           body: jsonEncode(<String, String>{
//             'npp': nrk.toString(),
//             "deviceId": _deviceId.toString(),
//           })
//       ).timeout(const Duration(seconds: 20));
//
//       final result = getResult.body.toString().replaceAll('""', "");
//
//       if (jsonDecode(result)['rcode'] == "00") {
//         if (this._inRadius) {
//           try {
//             final getResult = await http.post(
//                 Uri.parse(ApiConstants.BASE_URL+"/"+absenType),
//                 headers: <String, String> {
//                   'Content-Type': 'application/json; charset=UTF-8',
//                   'Authorization': 'Bearer $token'
//                 },
//                 body: jsonEncode(<String, String> {
//                   'npp': nrk.toString(),
//                   'latitude': lat.toString(),
//                   'longitude': long.toString(),
//                   'branch_id': branch_id
//                 })
//             ).timeout(const Duration(seconds: 20));
//
//             String result = getResult.body.toString().replaceAll('""', "");
//
//             if (jsonDecode(result)['rcode'] == "00") {
//
//               String message = jsonDecode(result)['message'];
//               Navigator.of(context,rootNavigator: true).pop(context);
//               QuickAlert.show(
//                 headerBackgroundColor:Colors.black,
//                 context: context,
//                 type: QuickAlertType.success,
//                 title: "Berhasil",
//                 text: message,
//                 confirmBtnText: 'Oke',
//                 confirmBtnColor: Color.fromRGBO(1, 101, 65, 1),
//               );
//
//             } else if (jsonDecode(result)['rcode'] == "02") {
//
//               String message = jsonDecode(result)['message'];
//               Navigator.of(context,rootNavigator: true).pop(context);
//
//               QuickAlert.show(
//                 headerBackgroundColor:Colors.black,
//                 context: context,
//                 type: QuickAlertType.info,
//                 title: "Info",
//                 text: message,
//                 confirmBtnText: 'Oke',
//                 // confirmBtnColor: Color.fromRGBO(1, 101, 65, 1),
//
//               );
//             }
//           } on TimeoutException catch (_) {
//
//             Navigator.of(context,rootNavigator: true).pop(context);
//             _fetchDialogWarning(context, "Koneksi timeout, silahkan coba lagi");
//
//           } catch (e) {
//
//             Navigator.of(context,rootNavigator: true).pop(context);
//             _fetchDialogWarning(context, "Koneksi timeout, silahkan coba lagi");
//           }
//
//         }else {
//
//           var message = "Anda berada diluar lokasi absen!";
//
//           Navigator.of(context,rootNavigator: true).pop(context);
//
//           QuickAlert.show(
//             context: context,
//             type: QuickAlertType.warning,
//             title: "Warning",
//             text: message,
//             confirmBtnColor : Color.fromRGBO(1, 101, 65, 1),
//             confirmBtnText: 'Oke',
//           );
//
//           return "absen gagal";
//         }
//
//       }else {
//         // Navigator.of(context,rootNavigator: true).pop(context);
//         // signOut();
//       }
//     } on TimeoutException catch (_) {
//       Navigator.of(context, rootNavigator: true).pop(context);
//       _fetchDialogWarning(context, "Koneksi timeout, silahkan coba lagi");
//     } catch (e) {
//       Navigator.of(context, rootNavigator: true).pop(context);
//       _fetchDialogWarning(context, "Koneksi timeout, silahkan coba lagi" + e.toString());
//     }
//
//     return "nrk";
//
//   }
//
//   signOut() async {
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.clear();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => Login())
//       );
//     });
//   }
//
//   String googleApikey = "GOOGLE_MAP_API_KEY";
//   LatLng startLocation = LatLng(27.6602292, 85.308027);
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold (
//         appBar: AppBar(
//             title: Text(
//                 'Absensi',
//                       style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),
//             ),
//             actions: [
//               Padding(
//                 padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton(
//                     icon: Icon(FluentIcons.options_20_filled,color: Colors.white,size: 25,),
//                     items: <DropdownMenuItem>[
//                       DropdownMenuItem(
//                         onTap: signOut,
//                         value: 'logout',
//                         child: Text('Logout'),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                       });
//                     },
//                   ),
//                 ),
//               ),
//           ],
//           backgroundColor: Color.fromRGBO(1, 101, 65, 1),
//         ),
//       // body: Scaffold(
//         body:
//         Stack(
//           children: [
//             Container (
//               child: SafeArea(
//                 child: currentLatLng == null ? Center(child:CircularProgressIndicator()) : GoogleMap(
//                   circles: Set.from([
//                     Circle(
//                       circleId: CircleId("2343"),
//                       center: LatLng(latKantor,longKantor),
//                       radius: radius,
//                       fillColor: Colors.orange.shade100.withOpacity(0.5),
//                       strokeColor:  Colors.orange.shade100.withOpacity(0.1)
//                     )
//                   ]),
//                   mapType: MapType.normal,
//                   myLocationEnabled: true,
//                   compassEnabled: true,
//                   initialCameraPosition: CameraPosition(target:  LatLng(5.521358096586348, 95.33064137456458), zoom: 10),
//                   onMapCreated: (GoogleMapController controller) {
//                     _controller.complete(controller);
//                   },
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                   margin: const EdgeInsets.only(left: 0.0, right: 0.0),
//                   height: 240,
//                   decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(50),
//                   boxShadow: [
//                   BoxShadow(
//                   color: Colors.black87.withOpacity(0.2),
//                   // color: Colors.white,
//                   blurRadius: 4,
//                   // spreadRadius: 1,
//                   offset: const Offset(0, 0)
//                   ),
//                   ]
//                   ),
//                   child:
//                         Card(
//                             margin: EdgeInsets.zero,
//                             color: Colors.orangeAccent[600],
//                             elevation: 20,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.only(topLeft:Radius.circular(30),topRight: Radius.circular(30))
//                             ),
//                             clipBehavior: Clip.hardEdge,
//                             child: Padding(
//                               padding: EdgeInsets.all(0.0),
//                               child:
//                               SizedBox(
//                                 height: 200,
//                                 width: double.infinity,
//                                 child:
//                                 Padding(
//                                     padding: EdgeInsets.all(20),
//                                     child:
//                                     Column(
//                                       children: [
//                                         Text( 'Silahkan Melakukan Absensi',
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//                                         ),
//                                         SizedBox(
//                                           width: 10,
//                                           height: 15,
//                                         ),
//
//                                         StreamBuilder(
//                                           builder: (context,snapshot) {
//                                             return  Text(
//                                               DateFormat('kk:mm:ss').format(DateTime.now()), textAlign: TextAlign.center,
//                                               style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600),
//                                             );
//                                           },
//                                           stream: Stream.periodic(const Duration(seconds: 1)),
//                                         ),
//
//                                         SizedBox(
//                                           width: 10,
//                                           height: 4,
//                                         ),
//                                         Text(
//                                           DateFormat('EEEE dd MMMM','id').format(DateTime.now()), textAlign: TextAlign.center,
//                                         ),
//                                         SizedBox(
//                                           width: 10,
//                                           height: 30,
//                                         ),
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           crossAxisAlignment: CrossAxisAlignment.center,
//                                           children: [
//                                             ElevatedButton(
//                                               onPressed: () {
//                                                 // _checkLogin();
//                                                 _checkRadius("absenmasuk");
//                                                 _fetchData(context);
//                                               } ,
//                                               child: Text("Masuk",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500),),
//                                               style:
//                                               // raisedButtonStyle
//                                               ElevatedButton.styleFrom(
//                                                 onPrimary:Color.fromRGBO(1, 101, 65, 1),
//                                                 primary: Color.fromRGBO(1, 101, 65, 1),
//                                                 // side: const BorderSide(color: Color.fromRGBO(1, 101, 65, 1),width: 1.9),
//                                                 // side: const BorderSide(color: Color.fromRGBO(1, 101, 65, 1),width: 1.9),
//                                                 minimumSize: Size(100, 40),
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               width: 10,
//                                               height: 15,
//                                             ),
//                                             ElevatedButton(
//                                               onPressed: () async {
//                                                 getUserCurrentLocation().then((value) async {
//                                                   print(value.latitude.toString() +"  "+value.longitude.toString());
//
//                                                   // specified current users location
//                                                   CameraPosition cameraPosition = new CameraPosition(
//                                                     // target: LatLng(latKantor, longKantor),
//                                                     target: LatLng(latKantor, longKantor),
//                                                     zoom: 17,
//                                                   );
//
//                                                   final GoogleMapController controller = await _controller.future;
//                                                   controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
//                                                   setState(() {
//                                                   });
//                                                 });
//                                               },
//                                               child: Icon(Icons.location_city_sharp,color: Color.fromRGBO(1, 101, 65, 1)),
//                                               // child: Text("Lok"),
//                                               style:
//                                               // raisedButtonStyle
//                                               ElevatedButton.styleFrom(
//                                                 onPrimary: Colors.white,
//                                                 primary: Colors.white,
//                                                 // onPrimary: Colors.white,
//                                                 // primary: Colors.white,
//                                                 side: const BorderSide(color: Color.fromRGBO(1, 101, 65, 1),width: 1.9),
//                                                 // primary: Color.fromRGBO(245, 216, 0, 1),
//                                                 minimumSize: Size(50, 40),
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               width: 10,
//                                               height: 15,
//                                             ),
//                                             ElevatedButton (
//                                               onPressed: () {
//                                                 _konfirmasiAbsenPulang(context, "message");
//                                                 // _checkRadius('absenpulang');
//                                                 // _fetchData(context);
//                                               } ,
//                                               child: Text("Pulang",style: TextStyle(color:Colors.white,fontWeight: FontWeight.w500),),
//                                               style:
//                                               // raisedButtonStyle
//                                               ElevatedButton.styleFrom(
//                                                 // onPrimary: Colors.white,
//                                                 // primary: Colors.white,
//                                                 // side: const BorderSide(color: Color.fromRGBO(1, 101, 65, 1),width: 1.9),
//                                                 // side: const BorderSide(color:Colors.orangeAccent,width: 1.9),
//                                                 onPrimary:Color.fromRGBO(1, 101, 65, 1),
//                                                 primary: Color.fromRGBO(1, 101, 65, 1),
//                                                 minimumSize: Size(100, 40),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     )
//                                 ),
//                               ),
//                             )
//                         ),
//               ),
//             )
//           ],
//         ),
//     );
//   }
// }
//
// class PresenceGeo extends GeolocatorPlatform {}
