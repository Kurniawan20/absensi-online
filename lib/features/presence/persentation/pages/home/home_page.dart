import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring_project/screens/page_rekap_absensi.dart';
import '../../../../../Models/DataEmployee.dart';
import '../../../../../controller/HomeController.dart';
import '../../../../../screens/Apis.dart';
import '../../../../../screens/page_login.dart';
import '../../../../../screens/page_webview_show_blog.dart';


class HomePage extends StatefulWidget {
  @override
  _Homescreenstate createState() => _Homescreenstate();
}

class _Homescreenstate extends State<HomePage> with WidgetsBindingObserver {

  SharedPreferences? preferences;
  late SharedPreferences _sharedPreferences;
  late Future<List<DataEmpoyee>> futureData;
  final storage = const FlutterSecureStorage();
  HomeController homeController = HomeController();

  @override
  void initState() {

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializePreference().whenComplete(() {
        setState(() {});
      });
    });

    homeController.fetchData();
    futureData = homeController.fetchData();
  }

  DateTime now = DateTime.now();

  Future<void> initializePreference() async {
    this.preferences = await SharedPreferences.getInstance();
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  final List<List> imgList = [];
  final List<List> blogList = [];

  Future<void> refreshData() async {

    _sharedPreferences = await SharedPreferences.getInstance();
    print(_sharedPreferences.getString("npp"));
    String? npp = _sharedPreferences.getString("npp");

    var token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse(ApiConstants.BASE_URL+"/getblog/${npp}"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );

    print(json.decode(response.body));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
      futureData = homeController.fetchData();
      homeController.fetchData();
      });
    } else {
      throw Exception('Unexpected error occured!');
    }
  }

  signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login()));
    });
  }

  @override
  Widget build(BuildContext context) {
    String greeting = "";
    int hours = now.hour;

    if (hours >= 1 && hours <= 12) {
      greeting = "Selamat Pagi";
    } else if (hours >= 12 && hours <= 16) {
      greeting = "Selamat Siang";
    } else if (hours >= 16 && hours <= 21) {
      greeting = "Selamat Sore";
    } else if (hours >= 21 && hours <= 24) {
      greeting = "Selamat Malam";
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(1, 101, 65, 1),
          bottomOpacity: 0.0,
          elevation: 0.0,
          centerTitle: false,
          title: const Text(
            'Beranda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  icon: Icon(
                    FluentIcons.options_20_filled,
                    color: Colors.white,
                    size: 25,
                  ),
                  items: <DropdownMenuItem>[
                    DropdownMenuItem(
                      onTap: signOut,
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
        body: Container(
            child: RefreshIndicator(
                onRefresh: () => refreshData(),
                child: ListView(
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
                          child: Column(
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                              ),
                              Center(
                                  child: SizedBox(
                                width: 500,
                                height: 120,
                                child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                            bottomRight: Radius.circular(10))),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(10, 22, 22, 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Icon(
                                                  FluentIcons
                                                      .person_board_28_filled,
                                                  size: 60,
                                                  color: Color.fromRGBO(
                                                      12, 68, 49, 1)),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(greeting,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color.fromRGBO(
                                                          12, 68, 49, 1),
                                                      fontFamily: 'Roboto')),
                                              SizedBox(
                                                width: 0,
                                                height: 4,
                                              ),
                                              Text(
                                                '${this.preferences?.getString("nama")} | ${this.preferences?.getString("npp")}'
                                                    .toTitleCase(),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromRGBO(
                                                        12, 68, 49, 1),
                                                    fontFamily: 'Roboto'),
                                              ),
                                              SizedBox(
                                                width: 0,
                                                height: 4,
                                              ),
                                              Text(
                                                  '${this.preferences?.getString("nama_kantor")} |  ${this.preferences?.getString("kode_kantor")}'
                                                      .toTitleCase(),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                          12, 68, 49, 1),
                                                      fontFamily: 'Roboto')),
                                              SizedBox(
                                                width: 0,
                                                height: 3,
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    )),
                              )),
                              SizedBox(
                                width: 0,
                                height: 5,
                              ),
                              Container(
                                  alignment: Alignment.bottomLeft,
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Card(
                                        elevation: 2,
                                        clipBehavior: Clip.antiAlias,
                                        color: Colors.white,
                                        child: InkWell(
                                          splashColor:
                                              Colors.blue.withAlpha(30),
                                          onTap: () => {
                                            Navigator.push<Widget>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RekapAbsensi(
                                                    id: "${this.preferences?.getString("npp")}"),
                                              ),
                                            )
                                          },
                                          child: Container(
                                            child: SizedBox(
                                              width: 105,
                                              height: 90,
                                              child: Center(
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          FluentIcons
                                                              .phone_screen_time_20_filled,
                                                          size: 43,
                                                          color: Color.fromRGBO(
                                                              12, 68, 49, 1)),
                                                      SizedBox(height: 10),
                                                      Text("Rekap Absensi",
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontFamily:
                                                                  'Roboto')),
                                                    ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                              Divider(
                                color: Colors.black12,
                                indent: 10,
                                endIndent: 10,
                                thickness: 1,
                              ),
                              SizedBox(
                                width: 0,
                                height: 13,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10.0),
                                child: Row(
                                  children: [
                                    Text("Informasi",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromRGBO(12, 68, 49, 1),
                                            fontFamily: 'Roboto')),
                                    SizedBox(
                                      width: 5,
                                      height: 0,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 0,
                                height: 13,
                              ),
                              SingleChildScrollView(
                                  child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: FutureBuilder<List<DataEmpoyee>>(
                                  future: futureData,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      List<DataEmpoyee> data = snapshot.data!;
                                      return ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: data.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Card(
                                              clipBehavior: Clip.hardEdge,
                                              child: InkWell(
                                                  splashColor:
                                                      Colors.blue.withAlpha(30),
                                                  onTap: () {
                                                    Navigator.push<Widget>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            WebViewApp(
                                                                id: data[index]
                                                                    .id
                                                                    .toString()),
                                                      ),
                                                    );
                                                    // debugPrint('Card tapped.');
                                                  },
                                                  child: ListTile(
                                                    title: Text(
                                                        data[index].title,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .black87)),
                                                    subtitle: Text(
                                                      data[index]
                                                          .createdAt
                                                          .substring(0, 10),
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                    // leading: Text(data[index].createdAt.substring(0,10)),
                                                    // trailing: Icon(FluentIcons
                                                    //     .book_information_24_filled),
                                                  )),
                                            );
                                          });
                                    } else if (snapshot.hasError) {
                                      return Text("${snapshot.error}");
                                    }
                                    // By default show a loading spinner.
                                    return CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Color.fromRGBO(1, 101, 65, 1)),
                                    );
                                  },
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ))));
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
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}
