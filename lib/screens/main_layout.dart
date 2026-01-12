import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_manager.dart';
import './home_page.dart';
import './page_presence.dart';
import './page_profile.dart';
import './page_login.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize session on app start
    SessionManager.initializeSession();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
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
              color: Colors.black.withOpacity(0.04),
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
