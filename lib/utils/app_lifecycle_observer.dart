import 'package:flutter/material.dart';

/// Mixin to handle app lifecycle events for background sync
/// Add this mixin to any StatefulWidget that needs to refresh data
/// when the app comes back to foreground
mixin AppLifecycleObserverMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      onAppResumed();
    }
  }

  /// Override this method to refresh data when app comes to foreground
  void onAppResumed() {
    // Override in your widget to refresh data
  }

  // Required WidgetsBindingObserver methods with default implementations
  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() => Future.value(false);

  @override
  Future<bool> didPushRoute(String route) => Future.value(false);

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      Future.value(false);
}
