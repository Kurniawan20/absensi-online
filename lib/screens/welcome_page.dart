import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'page_login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

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
      icon: 'assets/images/ic_launcher.png',
    ),
    OnboardingItem(
      title: 'Absensi Berbasis Lokasi',
      description:
          'Sistem memastikan keakuratan data dengan memverifikasi lokasi Anda berada di area kantor saat melakukan check-in.',
      icon: 'assets/images/onboarding_location.png',
    ),
    OnboardingItem(
      title: 'Pantau Riwayat Kehadiran',
      description:
          'Akses rekap kehadiran bulanan Anda dengan mudah dan dapatkan informasi detail mengenai jam masuk dan pulang.',
      icon: 'assets/images/onboarding_history.png',
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
    // Precache gambar agar transisi halus
    precacheImage(
      const ResizeImage(AssetImage('assets/images/ic_launcher.png'),
          width: 300),
      context,
    );
    precacheImage(
      const ResizeImage(AssetImage('assets/images/onboarding_location.png'),
          width: 600),
      context,
    );
    precacheImage(
      const ResizeImage(AssetImage('assets/images/onboarding_history.png'),
          width: 600),
      context,
    );
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _items.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel(); // Berhenti di halaman terakhir
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
    const primaryColor = Color.fromRGBO(1, 101, 65, 1);
    const backgroundColor = Color(0xFFF7F7F5);

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Ukuran gambar responsif berdasarkan lebar layar
    final imageSize = screenWidth * 0.45;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND LAYER (Static)
            Column(
              children: [
                // Area atas (scatter icons)
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      // Posisi relatif terhadap layar
                      _buildScatterIcon(
                        Icons.access_time_filled,
                        screenHeight * 0.04,
                        screenWidth * 0.1,
                        Colors.grey[300]!,
                        angle: -0.2,
                      ),
                      _buildScatterIcon(
                        Icons.location_on,
                        screenHeight * 0.10,
                        screenWidth * 0.78,
                        Colors.grey[300]!,
                        angle: 0.2,
                      ),
                      _buildScatterIcon(
                        Icons.calendar_today,
                        screenHeight * 0.28,
                        screenWidth * 0.12,
                        Colors.grey[300]!,
                        angle: -0.1,
                      ),
                      _buildScatterIcon(
                        Icons.fingerprint,
                        screenHeight * 0.22,
                        screenWidth * 0.82,
                        Colors.grey[300]!,
                        angle: 0.3,
                      ),
                      _buildScatterIcon(
                        Icons.notifications,
                        screenHeight * 0.14,
                        screenWidth * 0.08,
                        Colors.grey[300]!,
                        angle: 0.15,
                      ),
                      _buildScatterIcon(
                        Icons.history,
                        screenHeight * 0.06,
                        screenWidth * 0.60,
                        Colors.grey[300]!,
                        angle: -0.25,
                      ),
                    ],
                  ),
                ),
                // Area bawah (white card)
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
                final item = _items[index];
                // Halaman pertama (logo) lebih kecil, sisanya ukuran standar
                final currentImageSize =
                    index == 0 ? imageSize * 0.65 : imageSize;

                return Column(
                  children: [
                    // Bagian atas: Gambar/Icon
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Image.asset(
                          item.icon,
                          width: currentImageSize,
                          height: currentImageSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Bagian bawah: Teks
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.08, // Padding horizontal relatif
                          screenHeight * 0.03, // Padding top relatif
                          screenWidth * 0.08,
                          0,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
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
                const Spacer(flex: 4),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.08,
                      0,
                      screenWidth * 0.08,
                      screenHeight * 0.03,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Indikator Halaman
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

                        SizedBox(height: screenHeight * 0.025),

                        // Tombol Aksi
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.065,
                          child: ElevatedButton(
                            onPressed: _currentPage == _items.length - 1
                                ? _completeOnboarding
                                : () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
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
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          width: screenWidth * 0.25,
                          height: 5,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget ikon dekoratif dengan posisi responsif
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

/// Model data untuk setiap halaman onboarding
class OnboardingItem {
  final String title;
  final String description;
  final String icon;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
