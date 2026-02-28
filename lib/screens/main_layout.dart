import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import '../services/session_manager.dart';
import '../services/device_info_service.dart';
import '../services/notification_refresh_service.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import './home_page.dart';
import './page_presence.dart';
import './page_profile.dart';
import './page_login.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  StreamSubscription<void>? _notificationRefreshSubscription;
  String? _currentNpp;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize session on app start
    SessionManager.initializeSession();

    // Register FCM token if user is already logged in
    _registerFcmTokenIfNeeded();

    // Listen for notification refresh events
    _setupNotificationRefreshListener();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  void _setupNotificationRefreshListener() {
    _notificationRefreshSubscription = NotificationRefreshService().onRefresh.listen((_) {
      print('MainLayout: Received notification refresh event');
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    if (_currentNpp != null && mounted) {
      print('MainLayout: Refreshing notifications for $_currentNpp');
      context.read<NotificationBloc>().add(RefreshNotifications(npp: _currentNpp!));
    }
  }

  /// Register FCM token on app startup if user is already logged in
  Future<void> _registerFcmTokenIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final npp = prefs.getString('npp');
      final isLoggedIn = prefs.getBool('is_login') ?? false;

      if (npp == null || npp.isEmpty || !isLoggedIn) {
        print('FCM Registration skipped: User not logged in');
        return;
      }

      // Store NPP for later use
      _currentNpp = npp;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('FCM Registration skipped: FCM token is null');
        return;
      }

      final deviceId = await DeviceInfoService().getDeviceId();

      print('=== Registering FCM Token (App Startup) ===');
      print('NPP: $npp');
      print('FCM Token: ${fcmToken.substring(0, 20)}...');
      print('Device ID: $deviceId');

      if (mounted) {
        // Register FCM token
        context.read<NotificationBloc>().add(RegisterFcmToken(
          npp: npp,
          fcmToken: fcmToken,
          deviceId: deviceId,
        ));
        print('FCM token registration event dispatched');

        // Load notifications to show badge
        context.read<NotificationBloc>().add(LoadNotifications(npp: npp));
        print('Notifications load event dispatched');

        // Subscribe to broadcast topic
        await FirebaseMessaging.instance.subscribeToTopic('all');
        print('Subscribed to "all" topic');
      }
    } catch (e) {
      print('FCM Registration error (non-blocking): $e');
    }
  }

  @override
  void dispose() {
    // Cancel notification refresh subscription
    _notificationRefreshSubscription?.cancel();
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - check session
      _checkSessionTimeout();
      // Refresh notifications
      _refreshNotifications();
    } else if (state == AppLifecycleState.paused) {
      // App went to background - update activity timestamp
      SessionManager.updateActivity();
    }
  }

  Future<void> _checkSessionTimeout() async {
    if (SessionManager.isSessionExpired()) {
      // Session expired - logout user
      await _handleSessionExpired();
    } else {
      // Session still valid - update activity
      SessionManager.updateActivity();
    }
  }

  Future<void> _handleSessionExpired() async {
    // Clear session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SessionManager.resetSession();

    // Show session expired message and redirect to login
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  final List<Widget> _pages = [
    const HomePage(),
    const Presence(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
    // Update session activity on user interaction
    SessionManager.updateActivity();

    setState(() {
      _fadeController.reverse().then((_) {
        setState(() {
          _selectedIndex = index;
          _fadeController.forward();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromRGBO(
                1, 101, 65, 1), // Primary green for selected items
            unselectedItemColor: const Color(0xFF9E9E9E), // Grey for unselected
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2, top: 4),
                  child: Icon(
                    _selectedIndex == 0
                        ? FluentIcons.home_24_filled
                        : FluentIcons.home_24_regular,
                    size: 22,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2, top: 4),
                  child: Icon(
                    _selectedIndex == 1
                        ? FluentIcons.calendar_checkmark_24_filled
                        : FluentIcons.calendar_checkmark_24_regular,
                    size: 24,
                  ),
                ),
                label: 'Kehadiran',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2, top: 4),
                  child: Icon(
                    _selectedIndex == 2
                        ? FluentIcons.person_24_filled
                        : FluentIcons.person_24_regular,
                    size: 22,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
