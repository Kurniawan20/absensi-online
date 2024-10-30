import 'package:flutter/material.dart';
import 'package:monitoring_project/features/presence/persentation/pages/home/home_page.dart';
import 'package:monitoring_project/features/presence/persentation/pages/presence/page_presence.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _materialRoute(HomePage());

      case '/Presence':
        return _materialRoute(Presence());

      case '/PresenceData':
        return _materialRoute(HomePage());

      default:
        return _materialRoute(HomePage());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}
