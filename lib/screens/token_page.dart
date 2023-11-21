// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:monitoring_project/screens/notification_api.dart';
// import 'login.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:jwt_decode/jwt_decode.dart';
// import 'dart:convert';
// import 'presence.dart';
// import '../utils/notification_service.dart';
// import 'package:http/http.dart' as http;
// // import 'package:get_mac/get_mac.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import '../widget/dialogs.dart';
//
// class TokenPage extends StatefulWidget {
//   const TokenPage({Key? key}) : super(key: key);
//   static const String id = 'home_page';
//   static const String expiryDate = "";
//
//   @override
//   _Homescreenstate createState() => _Homescreenstate();
// }
//
// class _Homescreenstate extends State<TokenPage> {
//
//   // late final NotificationService notificationService;
//   // SharedPreferences? preferences;
//   // Timer? timer;
//
//   @override
//   void initState() {
//
//     notificationService = NotificationService();
//     notificationService.initializePlatformNotifications();
//     NotificationApi.init();
//     super.initState();
//     initializePreference().whenComplete((){
//       setState(() {});
//     });
//
//     timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _checkDataToken());
//   }
//
//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }
//
//   // void fireToast(String message) {
//   //   Fluttertoast.showToast(
//   //       msg: message,
//   //       toastLength: Toast.LENGTH_SHORT,
//   //       gravity: ToastGravity.CENTER,
//   //       timeInSecForIosWeb: 1,
//   //       backgroundColor: Colors.red,
//   //       textColor: Colors.white,
//   //       fontSize: 16.0
//   //   );
//   // }
//
//   signOut() async {
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.clear();
//
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => Login())
//     );
//   }
//
//   String _deviceMAC = 'Click the button.';
//
//   // Future<void> initMacAddress() async {
//   //
//   //   String macAddress;
//   //
//   //   try {
//   //     macAddress = await GetMac.macAddress;
//   //   } on PlatformException {
//   //     macAddress = 'Error getting the MAC address.';
//   //   }
//   //
//   //   setState(() {
//   //     _deviceMAC = macAddress;
//   //   });
//   //
//   //   print("mac address "+ macAddress);
//   // }
//
//   String token = '';
//   String expired = '';
//   bool status =true;
//
//   Future<String> _checkDataToken() async {
//
//     final nrk = preferences?.getString("npp");
//     final nrk2 = jsonDecode(nrk!);
//     String nrk3 = nrk2.toString();
//
//     print(nrk);
//
//     try {
//       final getResult = await http.post(
//
//           Uri.parse("http://192.168.100.16/mobile-auth-api/public/api/generatetoken"),
//           headers: <String, String> {
//             'Content-Type': 'application/json; charset=UTF-8',
//           },
//           body: jsonEncode(<String, String>{
//             'npp': nrk3,
//           })
//
//       ).timeout(
//           const Duration(seconds: 1),
//           onTimeout: () {
//             return http.Response('error',408);
//           }
//       );
//
//       String result = getResult.body.toString().replaceAll('""',"");
//
//       setState(() {
//         token = jsonDecode(result)['token'];
//         expired = jsonDecode(result)['expired'];
//         status = jsonDecode(result)['status'];
//       });
//
//       return result.toString();
//
//     }on TimeoutException catch (e) {
//       // print ('21423');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text(
//               e.toString(),
//               style: const TextStyle(fontSize: 16),
//             )
//         ),
//       );
//     }
//     return "";
//     saveSession(token);
//   }
//   Future<String> _fetchDataToken() async {
//
//     final nrk = preferences?.getString("npp");
//     final nrk2 = jsonDecode(nrk!);
//     String nrk3 = nrk2.toString();
//
//     final getResult = await http.post(
//
//         Uri.parse("http://192.168.100.16/mobile-auth-api/public/api/generatetoken"),
//         headers: <String, String> {
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(<String, String>{
//           'npp': nrk3,
//         })
//     );
//
//     String result = getResult.body.toString().replaceAll('""',"");
//
//     // Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//           content: Text(
//             jsonDecode(result)['message'].toString(),
//             style: const TextStyle(fontSize: 16),
//           )
//       ),
//     );
//
//     setState(() {
//       token = jsonDecode(result)['token'];
//       expired = jsonDecode(result)['expired'];
//       status = jsonDecode(result)['status'];
//     });
//
//     saveSession(token);
//
//     return result.toString();
//   }
//
//   saveSession(String npp) async {
//
//     SharedPreferences pref = await SharedPreferences.getInstance();
//
//     pref.setString("token", token);
//     pref.setString("expired", expired);
//     pref.setBool("status", status);
//   }
//
//   Future<void> initializePreference() async {
//     this.preferences = await SharedPreferences.getInstance();
//     var _token = "";
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _token = prefs.getString("token")!;
//     Map<String, dynamic> payload = Jwt.parseJwt(_token);
//     DateTime? expiryDate = Jwt.getExpiryDate(_token);
//   }
//
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold (
//       appBar:AppBar(
//         automaticallyImplyLeading: false,
//         title: Text('Home'),
//         actions: [
//           DropdownButtonHideUnderline(
//             child: DropdownButton(
//               icon: Icon(Icons.menu,color: Colors.white),
//               // style: ,
//               // value: dropdownValue,
//               items: <DropdownMenuItem>[
//                 DropdownMenuItem(
//                   onTap: signOut,
//                   value: 'logout',
//                   child: Text('Logout'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   // dropdownValue = value;
//                 });
//               },
//             ),
//           ),
//         ],
//         backgroundColor: Colors.green,
//       ),
//       body:
//       // Column(
//       //   children: [
//       ListView(
//         children: [
//           ListTile(
//             title: Text('Nama'),
//             subtitle: Text('${this.preferences?.getString("nama")}'),
//           ),
//           ListTile(
//             title: Text('NPP'),
//             subtitle: Text('${this.preferences?.getString("npp")}'),
//           ),ListTile(
//             title: Text('Kode Kantor'),
//             subtitle: Text('${this.preferences?.getString("kode_kantor")}'),
//           ),
//           ListTile(
//             title: Text('MAC'),
//             subtitle: Text(_deviceMAC),
//           ),
//           ListTile(
//             title: Text('Token'),
//             subtitle: Text('${this.preferences?.getString("token")}'),
//           ),ListTile(
//             title: Text('Expired'),
//             subtitle: Text('${this.preferences?.getString("expired")}'),
//           ),ListTile(
//             title: Text('Status'),
//             subtitle: Text('${this.preferences?.getBool("status")}'.toUpperCase()),
//           ),
//           SizedBox(
//               width: 10, // <-- match_parent
//               height: 50, // <-- match-parent
//               child: ElevatedButton(
//                 style: raisedButtonStyle,
//                 onPressed: () {
//                   _fetchDataToken();
//                 },
//                 child: new Text('Generate Token'),
//               )
//           )
//           ,
//           // ElevatedButton(
//           // onPressed: () {
//           // initMacAddress();
//           // },
//           // child: const Text("Get MAC Address"),
//           // )
//           // ElevatedButton(onPressed: signOut, child: Text('Logout'))
//         ],
//       ),
//       // ],
//       // )
//     );
//   }
// }
