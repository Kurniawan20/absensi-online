import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'page_login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Selamat Datang di HABA!',
      description:
          'Nikmati kemudahan melakukan absensi harian dan pantau kehadiran Anda hanya dalam satu genggaman tangan.',
      content: Image.asset(
        'assets/images/ic_launcher.png',
        width: 140,
        height: 140,
        fit: BoxFit.contain,
        cacheWidth: 300,
      ),
    ),
    OnboardingItem(
      title: 'Absensi Berbasis Lokasi',
      description:
          'Sistem memastikan keakuratan data dengan memverifikasi lokasi Anda berada di area kantor saat melakukan check-in.',
      content: Image.asset(
        'assets/images/onboarding_location.png',
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        cacheWidth: 600,
      ),
    ),
    OnboardingItem(
      title: 'Pantau Riwayat Kehadiran',
      description:
          'Akses rekap kehadiran bulanan Anda dengan mudah dan dapatkan informasi detail mengenai jam masuk dan pulang.',
      content: Image.asset(
        'assets/images/onboarding_history.png',
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        cacheWidth: 600,
      ),
    ),
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache optimized versions of the images (width ~600px is enough for mobile)
    precacheImage(
        const ResizeImage(const AssetImage('assets/images/ic_launcher.png'),
            width: 300),
        context);
    precacheImage(
        const ResizeImage(
            const AssetImage('assets/images/onboarding_location.png'),
            width: 600),
        context);
    precacheImage(
        const ResizeImage(
            const AssetImage('assets/images/onboarding_history.png'),
            width: 600),
        context);
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _items.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Optional: Loop back to start or stop
        // _pageController.jumpToPage(0);
        timer.cancel(); // Stop at last page
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Login(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // App Brand Color
    const primaryColor = Color.fromRGBO(1, 101, 65, 1);
    const backgroundColor = Color(0xFFF7F7F5); // Off-white like the design

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // BACKGROUND LAYER (Static)
          Column(
            children: [
              // Top Background (Scatter Icons)
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    _buildScatterIcon(
                      Icons.access_time_filled,
                      60,
                      40,
                      Colors.grey[300]!,
                      angle: -0.2,
                    ),
                    _buildScatterIcon(
                      Icons.location_on,
                      120,
                      300,
                      Colors.grey[300]!,
                      angle: 0.2,
                    ),
                    _buildScatterIcon(
                      Icons.calendar_today,
                      300,
                      50,
                      Colors.grey[300]!,
                      angle: -0.1,
                    ),
                    _buildScatterIcon(
                      Icons.fingerprint,
                      250,
                      320,
                      Colors.grey[300]!,
                      angle: 0.3,
                    ),
                    _buildScatterIcon(
                      Icons.notifications,
                      150,
                      40,
                      Colors.grey[300]!,
                      angle: 0.15,
                    ),
                    _buildScatterIcon(
                      Icons.history,
                      80,
                      250,
                      Colors.grey[300]!,
                      angle: -0.25,
                    ),
                  ],
                ),
              ),
              // Bottom Background (White Card)
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        offset: Offset(0, -4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // CONTENT LAYER (Sliding Content)
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  // Top Section Content (Logo/Icon)
                  Expanded(
                    flex: 4,
                    child: Center(child: _items[index].content),
                  ),
                  // Bottom Section Content (Text)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              _items[index].title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _items[index].description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                height: 1.4,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // CONTROL LAYER (Indicators & Button - Static)
          Column(
            children: [
              const Spacer(flex: 4), // Matches top section
              Expanded(
                flex: 5, // Matches bottom section
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            color: _currentPage == index
                                ? primaryColor
                                : Colors.grey[300],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _currentPage == _items.length - 1
                              ? _completeOnboarding
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentPage == _items.length - 1
                                ? 'Mulai Sekarang'
                                : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(width: 100, height: 5, color: Colors.grey[200]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScatterIcon(
    IconData icon,
    double top,
    double left,
    Color color, {
    double angle = 0,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: angle,
        child: Icon(icon, size: 32, color: color),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final Widget content;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.content,
  });
}
