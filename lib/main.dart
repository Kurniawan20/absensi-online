import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitoring_project/screens/emulator_warning.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './home_page.dart';
import './screens/login.dart';
import './screens/presence.dart';
import 'utils/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

void main()=> runApp(MyMain());

@override
class MyMain extends StatefulWidget {
  @override
  _MyMainState createState() => _MyMainState();
}

class _MyMainState extends State<MyMain> with WidgetsBindingObserver{

  bool? _jailbroken;
  bool? _developerMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    _checkLogin();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool jailbroken;
    bool developerMode;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
      developerMode = await FlutterJailbreakDetection.developerMode;
    } on PlatformException {
      jailbroken = true;
      developerMode = true;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    // if (!mounted) return;

    setState(() {
      _jailbroken = jailbroken;
      _developerMode = developerMode;
      print("DEVELOPER MODE ${_developerMode}");

      if(_developerMode == true) {
        var message = "Mohon matikan developer mode anda!";
        print(message);

        // Navigator.push(
        //   context,
        //   new MaterialPageRoute(builder: (context) =>EmulatorWarning(message: message,)),
        // );

        // Navigator.pushReplacement(
        //     context, MaterialPageRoute(builder: (context) => EmulatorWarning(message: message,))
        // );
      }

    });


  }

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

  SharedPreferences? preferences;
  bool season = true;
  // late final NotificationService notificationService;

  bool isLogin = false;

  Future<void> _checkLogin() async {
    print("Developer MODE ${_developerMode}");

    final prefs = await SharedPreferences.getInstance();
    isLogin = prefs.getBool("is_login") ?? false;
    print( isLogin);
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    print(androidInfo.isPhysicalDevice);

    // if(androidInfo.isPhysicalDevice == false) {
    //   var message = "Anda terdeteksi menggunakan emulator!";
    //   Navigator.pushReplacement(
    //       context, MaterialPageRoute(builder: (context) => EmulatorWarning(message: message,))
    //   );
    //
    // } else {
    //
    //   if(isLogin == false) {
    //     Navigator.pushReplacement (
    //         context, MaterialPageRoute(builder: (context) => Login())
    //     );
    //     season = false;
    //   }
    // }
  }

  List pages = [
    HomePage(),
  ];

  List pages2 = [
    Login(),
    HomePage(),
  ];

  int currentIndex = 0;

  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    var item = BottomNavigationBar(
      onTap: onTap,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor:Color.fromRGBO(1, 101, 65, 1),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(.60),
      selectedFontSize: 14,
      unselectedFontSize: 14,
      showUnselectedLabels: false,
      showSelectedLabels: true,
      items: [
        BottomNavigationBarItem(
          label:  'Home',
          icon: Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: Icon(FluentIcons.home_28_filled,size: 28) ,),
        ),
        BottomNavigationBarItem(
          label: 'Presence',
          icon: Container(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
              child: Icon(FluentIcons.presence_away_24_filled,size: 28  ,)),

        ),
      ],
      selectedLabelStyle: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),
    );

    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder:
            (BuildContext context, AsyncSnapshot<SharedPreferences> prefs) {
          var x = prefs.data;
          if (prefs.hasData) {
            var isLogin2 = x?.getBool("is_login") ?? false;
            // isLogin ? HomePage() : Login();
            if (isLogin2) {
              return MaterialApp(
                  home: Scaffold(
                    body: IndexedStack(
                      index: currentIndex,
                      children:[
                        HomePage(),
                        Presence(),
                      ],
                    ),
                    bottomNavigationBar: item,
                  ),localizationsDelegates: [

                  GlobalWidgetsLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  MonthYearPickerLocalizations.delegate
                  ]
              );
            }
          }
          return MaterialApp(
              home: Login(),
                localizationsDelegates: [
                GlobalWidgetsLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                MonthYearPickerLocalizations.delegate
          ]);
        });
  }
}

class LocationPermissions {
}
