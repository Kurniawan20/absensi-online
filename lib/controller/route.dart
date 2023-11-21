import 'package:flutter/material.dart';
import '../home_page.dart';
import '../screens/presence.dart';

void main() => runApp(Route());

class Route extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Named Routes Demo',
      // Start the app with the "/" named route. In this case, the app starts
      // on the FirstScreen widget.
      initialRoute: '/',
      // onGenerateRoute: ,
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => HomePage(),
        // When navigating to the "/second" route, build the SecondScreen widget.
        // '/daftaratm': (context) => const Presence()
      },
    );
  }
}