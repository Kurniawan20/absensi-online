import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:monitoring_project/screens/notification_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splashscreen/splashscreen.dart';
import './home_page.dart';
import './screens/login.dart';
import './screens/splashscreen.dart';
import './screens/presence.dart';
import './screens/detail_atm.dart';
import 'utils/notification_service.dart';
import './screens/token_page.dart';


void main()=> runApp((MaterialApp(home: MyMain(),)));

@override
class MyMain extends StatefulWidget {
  @override
  _MyMainState createState() => _MyMainState();
}

class _MyMainState extends State<MyMain> {


  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  SharedPreferences? preferences;
  late final NotificationService notificationService;

  void listenNotifications() =>
      NotificationApi.onNotifications.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MyApp()
      ));


  Future<void> _checkLogin() async {
    print("asdfasdf");

    final prefs = await SharedPreferences.getInstance();
    bool branch_id = prefs.getBool("kode_kantor") ?? false;

    if(branch_id == false) {

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login()));
    });

    }

  }

  void _changeSelectedNavBar(int index) {
    setState(() {
      switch (index) {
        case 0 :
          MaterialPageRoute(builder: (context) => HomePage());
          break;
        case 1 :
          MaterialPageRoute(builder: (context) => MyApp());
          break;
      }
    });
  }

  List pages = [
    HomePage(),
    MyApp(),
    TokenPage()
  ];

  Future<void> initializePreference() async{
    this.preferences = await SharedPreferences.getInstance();
    var _token = "";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token")!;
    Map<String, dynamic> payload = Jwt.parseJwt(_token);
    DateTime? expiryDate = Jwt.getExpiryDate(_token);

    // if(_token.isEmpty || _token == null){
      pages.insert(0, Login());
    // }

    print(pages);

  }

  int currentIndex = 0;


  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          body:
          pages[currentIndex],
          bottomNavigationBar:
          BottomNavigationBar(
            onTap: onTap,
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.green,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(.60),
            selectedFontSize: 14,
            unselectedFontSize: 14,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(Icons.home),
              ),
              BottomNavigationBarItem(
                label: 'Presence',
                icon: Icon(Icons.access_time_filled),
              ),
              BottomNavigationBarItem(
                label: 'Profile',
                icon: Icon(Icons.person),
              ),
            ],
          ),
        )
    );
  }
}
