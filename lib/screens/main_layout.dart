import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import './home_page.dart';
import './page_presence.dart';
import './page_profile.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _fadeController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const HomePage(),
    const Presence(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
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
        height: 65, // Total height including shadow
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
          child: SizedBox(
            height: 70, // Navigation bar content height
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white, // Changed to white background
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color.fromRGBO(
                  1, 101, 65, 1), // Primary green for selected items
              unselectedItemColor:
                  const Color(0xFF9E9E9E), // Grey for unselected
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Icon(
                      _selectedIndex == 0
                          ? FluentIcons.home_24_filled
                          : FluentIcons.home_24_regular,
                      size: 24,
                    ),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Icon(
                      _selectedIndex == 1
                          ? FluentIcons.presence_available_10_filled
                          : FluentIcons.presence_available_10_regular,
                      size: 24,
                    ),
                  ),
                  label: 'Kehadiran',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Icon(
                      _selectedIndex == 2
                          ? FluentIcons.person_24_filled
                          : FluentIcons.person_24_regular,
                      size: 24,
                    ),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
