import 'dart:async';
import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitoring_project/screens/rekapAbsensi.dart';
import './screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './screens/webviewShowBlog.dart';

class HomePage extends StatefulWidget {
  @override
  _Homescreenstate createState() => _Homescreenstate();
}

class _Homescreenstate extends State<HomePage> with WidgetsBindingObserver {

  SharedPreferences? preferences;
  late Future <List<Data>> futureData;
  late SharedPreferences _sharedPreferences;

  @override
  void initState() {

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializePreference().whenComplete((){
        setState(() {});
      });
    });

    print("nppp ${this.preferences?.getString("npp")}");

    futureData = fetchData();
  }
  DateTime now = DateTime.now();


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
  }

  Future<void> initializePreference() async {
    this.preferences = await SharedPreferences.getInstance();
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  Future<String?> getUsername() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    return _sharedPreferences.getString("npp");
  }

  final List<List> imgList = [];
  final List<List> blogList = [];

  signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login())
      );
    });
  }

  final Null _bids = (() {
    late final StreamController<int> controller;
    controller = StreamController<int>(
      onListen: () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        controller.add(1);
        await Future<void>.delayed(const Duration(seconds: 1));
        await controller.close();
      },
    );
  })();

  Future <List<Data>> fetchData() async {

    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    String? npp = _sharedPreferences.getString("npp");

    // final response = await http.get(Uri.parse("http://192.168.100.174/mobile-auth-api/public/api/getblog/${npp}"));
    final response = await http.post(Uri.parse("http://rsk.mcndev.my.id/api/getblog/${npp}"));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => new Data.fromJson(data)).toList();
    } else {
      throw Exception('Unexpected error occured!');
    }
  }

  Future<void> _refresh()  async {

    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    String? npp = _sharedPreferences.getString("npp");

    final response = await http.post(Uri.parse("http://rsk.mcndev.my.id/api/getblog/${npp}"));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);

      setState(() {
        futureData  = fetchData();
        fetchData();
      });

    } else {

      throw Exception('Unexpected error occured!');
    }
  }

  @override
  Widget build(BuildContext context) {

    String greeting = "";
    int hours= now.hour;

    if(hours>=1 && hours<=12){
      greeting = "Selamat Pagi";
    } else if(hours>=12 && hours<=16){
      greeting = "Selamat Siang";
    } else if(hours>=16 && hours<=21){
      greeting = "Selamat Sore";
    } else if(hours>=21 && hours<=24){
      greeting = "Selamat Malam";
    }

    return Scaffold (
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(1, 101, 65, 1),
        bottomOpacity: 0.0,
        elevation: 0.0,
        centerTitle: false,
        title: const Text('Home',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                icon: Icon(FluentIcons.options_20_filled,color: Colors.white,size: 25,),
                items: <DropdownMenuItem>[
                  DropdownMenuItem(
                    onTap: signOut,
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body:
        Container(
            child:
            RefreshIndicator(
              onRefresh: _refresh,
              child:
              ListView(
                shrinkWrap: false,
                children: [
                  Stack(
                    children: [
                      ClipPath(
                        clipper: CustomShape(),
                        child: Container(
                          height: 150,
                          color: Color.fromRGBO(1, 101, 65, 1),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child:Column(
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                            ),
                            Center(
                                child:
                                SizedBox (
                                  width: 500,
                                  height: 120,
                                  child: Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(topLeft:Radius.circular(10),topRight: Radius.circular(10),bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10))
                                      ),
                                      child:
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(10, 22, 22, 10),
                                        child:
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                Icon(FluentIcons.person_board_28_filled  ,size: 60,color:Color.fromRGBO(12, 68, 49, 1)),
                                                SizedBox(
                                                  width: 0,
                                                  height: 3,
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 15,
                                              height: 3,
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(greeting, style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500, color: Color.fromRGBO(12, 68, 49, 1),fontFamily: 'Roboto')),
                                                SizedBox(
                                                  width: 0,
                                                  height: 4,
                                                ),
                                                Text('${this.preferences?.getString("nama")} | ${this.preferences?.getString("npp")}'.toTitleCase() , style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(12, 68, 49, 1),fontFamily: 'Roboto'),),
                                                SizedBox(
                                                  width: 0,
                                                  height: 4,
                                                ),
                                                // Text('${this.preferences?.getString("npp")}'.toTitleCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(12, 68, 49, 1)),),
                                                // // Icon(Icons.account_balance,size: 30),
                                                // SizedBox(
                                                //   width: 0,
                                                //   height: 3,
                                                // ),
                                                // Text("Divisi Teknologi Informasi", style: TextStyle(fontWeight: FontWeight.bold)),
                                                Text('${this.preferences?.getString("nama_kantor")} |  ${this.preferences?.getString("kode_kantor")}'.toTitleCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(12, 68, 49, 1),fontFamily: 'Roboto')),
                                                SizedBox(
                                                  width: 0,
                                                  height: 3,
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                  ) ,
                                )
                            ),
                            SizedBox(
                              width: 0,
                              height: 5,
                            ),
                            // Divider(color: Colors.black12,indent: 10, endIndent: 10,thickness: 1,),
                            Container(
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(10),
                                child:
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Card(
                                      elevation: 2,
                                      clipBehavior: Clip.antiAlias,
                                      color: Colors.white,
                                      child: InkWell(
                                        splashColor: Colors.blue.withAlpha(30),
                                        onTap: () => {
                                          Navigator.push<Widget>(context,
                                            MaterialPageRoute(
                                              builder: (context) => RekapAbsensi(id: "${this.preferences?.getString("npp")}"),
                                            ),
                                          )
                                        } ,
                                        child: Container(
                                          // padding: EdgeInsets.fromLTRB(10.0,30.0,10,30.0),
                                          child: SizedBox(
                                            width: 105,
                                            height: 90,
                                            child:Center(
                                              child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(FluentIcons.phone_screen_time_20_filled,size: 43,color: Color.fromRGBO(12, 68, 49, 1)),
                                                    SizedBox(height: 10),
                                                    Text("Rekap Absensi",style: TextStyle(fontSize: 11,fontWeight: FontWeight.w600,fontFamily: 'Roboto')),
                                                  ]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                            ),
                            Divider(color: Colors.black12,indent: 10, endIndent: 10,thickness: 1,),
                            SizedBox(
                              width: 0,
                              height: 13,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                              child: Row(
                                children: [
                                  Text("Pengumuman",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Color.fromRGBO(12, 68, 49, 1),fontFamily: 'Roboto')),
                                  SizedBox(
                                    width: 5,
                                    height: 0,
                                  ),
                                  Icon(Icons.info_outlined,color: Color.fromRGBO(12, 68, 49, 1))
                                ],
                              ) ,
                            ),
                            SizedBox(
                              width: 0,
                              height: 13,
                            ),
                            // Expanded(
                            //     child:
                            // Padding(
                            //   padding:const EdgeInsets.only(left: 8.0, right: 8.0),
                            //   child:
                            //   FutureBuilder <List<Data>> (
                            //     future: futureData,
                            //     builder: (context,snapshot) {
                            //       if (snapshot.hasData) {
                            //         List<Data> data = snapshot.data!;
                            //         return
                            //           ListView.builder(
                            //               shrinkWrap: true,
                            //               scrollDirection: Axis.vertical,
                            //               itemCount: data.length,
                            //               itemBuilder: (BuildContext context, int index) {
                            //                 return
                            //                   Card(
                            //                     clipBehavior: Clip.hardEdge,
                            //                     child: InkWell(
                            //                         splashColor: Colors.blue.withAlpha(30),
                            //                         onTap: () {
                            //                           Navigator.push<Widget>(context,
                            //                             MaterialPageRoute(
                            //                               builder: (context) => WebViewApp(id: data[index].id.toString()),
                            //                             ),
                            //                           );
                            //                           // debugPrint('Card tapped.');
                            //                         },
                            //                         child: ListTile(
                            //                           title: Text(data[index].title, style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.black87)),
                            //                           subtitle: Text(data[index].createdAt.substring(0,10),style: TextStyle(fontSize: 13),),
                            //                           // leading: Text(data[index].createdAt.substring(0,10)),
                            //                           trailing: Icon(FluentIcons.book_information_24_filled),
                            //
                            //                         )
                            //                     ),
                            //                   );
                            //               }
                            //           );
                            //       } else if (snapshot.hasError) {
                            //         return Text("${snapshot.error}");
                            //       }
                            //       // By default show a loading spinner.
                            //       return CircularProgressIndicator();
                            //     },
                            //   ),
                            // )
                            // ),
                          ],
                        ) ,
                      ),
                    ],
                  ),
                ],
              )
            )
        )
    );
  }
}

class Data {
  final int id;
  final String title;
  final String body;
  final String file;
  final String image;
  final String createdAt;

  Data({required this.id, required this.title,required this.body,required this.file,required this.image,required this.createdAt});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      file: json['file'],
      image: json['image'],
      createdAt: json['created_at'],
    );
  }
}

class CustomShape extends CustomClipper<Path> {

  @override
  getClip(Size size) {
    double height = size.height;
    double width = size.width;
    var path = Path();
    path.lineTo(0, height - 70);
    path.quadraticBezierTo(width / 2, height, width, height - 70);
    path.lineTo(width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}
