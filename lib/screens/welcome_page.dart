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
  Timer? _timer;

  static const _primaryColor = Color.fromRGBO(1, 101, 65, 1);
  static const _bgColor = Colors.white;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Selamat Datang di HABA!',
      description:
          'Nikmati kemudahan melakukan absensi harian dan pantau kehadiran Anda hanya dalam satu genggaman tangan.',
      image: 'assets/images/onboarding_welcome.png',
      accent: Color(0xFFE8F5EE),
    ),
    _OnboardingItem(
      title: 'Absensi Berbasis Lokasi',
      description:
          'Sistem memastikan keakuratan data dengan memverifikasi lokasi Anda berada di area kantor saat melakukan check-in.',
      image: 'assets/images/onboarding_location.png',
      accent: Color(0xFFE8F1FB),
    ),
    _OnboardingItem(
      title: 'Pantau Riwayat Kehadiran',
      description:
          'Akses rekap kehadiran bulanan Anda dengan mudah dan dapatkan informasi detail mengenai jam masuk dan pulang.',
      image: 'assets/images/onboarding_history.png',
      accent: Color(0xFFFDF3E8),
    ),
    _OnboardingItem(
      title: 'Informasi & Pengumuman',
      description:
          'Dapatkan notifikasi pengumuman terkini dari manajemen langsung di genggaman Anda. Tidak ada informasi penting yang terlewat.',
      image: 'assets/images/onboarding_announcement.png',
      accent: Color(0xFFEEF2FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
    // Tandai onboarding sudah dilihat sejak pertama kali WelcomePage dibuka.
    // Ini mencegah onboarding muncul kembali jika app dimatikan di tengah proses.
    _markOnboardingSeen();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache semua gambar agar transisi halus
    for (final item in _items) {
      precacheImage(AssetImage(item.image), context);
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentPage < _items.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
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
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tombol Skip: selalu ada agar tinggi header konsisten ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Opacity(
                    opacity: isLastPage ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isLastPage,
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Konten slide: gambar + teks dalam satu PageView ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Column(
                      children: [
                        // Gambar
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(28)),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Image.asset(
                              _items[index].image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.03),

                        // Teks
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Text(
                                _items[index].title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: w * 0.057,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: h * 0.015),
                              Text(
                                _items[index].description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: w * 0.035,
                                  color: Colors.grey[500],
                                  height: 1.6,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Indikator halaman ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? _primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            SizedBox(height: h * 0.02),

            // ── Tombol aksi ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.08,
                0,
                w * 0.08,
                h * 0.04,
              ),
              child: SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: isLastPage
                      ? _completeOnboarding
                      : () {
                          _timer?.cancel();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Model data untuk setiap halaman onboarding
class _OnboardingItem {
  final String title;
  final String description;
  final String image;
  final Color accent;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
    required this.accent,
  });
}
