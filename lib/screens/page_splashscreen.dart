import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../bloc/app_version/app_version_bloc.dart';
import '../bloc/app_version/app_version_event.dart';
import '../bloc/app_version/app_version_state.dart';
import '../widgets/app_version/update_dialog.dart';
import '../widgets/app_version/network_error_screen.dart';
import 'maintenance_screen.dart';
import 'page_login.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _swingController; // For lanterns
  late AnimationController _pulseController; // For moon glow

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;
  late Animation<double> _mosqueRise;
  late Animation<double> _fadeInElements; // For moon/lanterns

  bool _animationComplete = false;
  bool _versionCheckComplete = false;
  AppVersionState? _pendingVersionState;

  // Premium Gold Particles
  final List<_GoldParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize 40 Gold Particles (slightly reduced for performance with new elements)
    for (int i = 0; i < 40; i++) {
      _particles.add(_GoldParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.2 + 0.05,
        opacity: _random.nextDouble() * 0.5 + 0.3,
        wobble: _random.nextDouble() * math.pi * 2,
      ));
    }

    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _swingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Staggered Animations
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _fadeInElements = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _mosqueRise = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _startAppFlow();
    _startVersionCheck();
  }

  void _startAppFlow() async {
    _mainController.forward();

    // Minimum Splash Duration
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _animationComplete = true);
      _checkAndProceed();
    }
  }

  void _startVersionCheck() {
    context.read<AppVersionBloc>().add(const CheckAppVersion());
  }

  void _checkAndProceed() {
    if (_animationComplete &&
        _versionCheckComplete &&
        _pendingVersionState != null) {
      _handleVersionState(_pendingVersionState!);
    }
  }

  void _handleVersionState(AppVersionState state) {
    if (!mounted) return;

    if (state is AppVersionUpToDate) {
      _navigateToNextScreen();
    } else if (state is AppVersionMaintenance) {
      _navigateToMaintenance(state.message);
    } else if (state is AppVersionUpdateAvailable) {
      if (state.isForced) {
        _showForceUpdateDialog(state);
      } else {
        _showOptionalUpdateDialog(state);
      }
    } else if (state is AppVersionNetworkError) {
      _navigateToNetworkError(state);
    }
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              hasSeenOnboarding ? const Login() : const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _navigateToMaintenance(String message) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MaintenanceScreen(
            message: message,
            onRetry: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _showForceUpdateDialog(AppVersionUpdateAvailable state) {
    UpdateDialog.show(
      context,
      info: state.info,
      isForced: true,
    );
  }

  void _showOptionalUpdateDialog(AppVersionUpdateAvailable state) {
    UpdateDialog.show(
      context,
      info: state.info,
      isForced: false,
      onSkip: () {
        Navigator.of(context).pop();
        context.read<AppVersionBloc>().add(const SkipOptionalUpdate());
      },
    );
  }

  void _navigateToNetworkError(AppVersionNetworkError state) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              NetworkErrorScreen(
            retryCount: state.retryCount,
            nextRetrySeconds: state.nextRetrySeconds,
            errorMessage: state.errorMessage,
            onManualRetry: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _swingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppVersionBloc, AppVersionState>(
      listener: (context, state) {
        if (state is AppVersionUpToDate ||
            state is AppVersionMaintenance ||
            state is AppVersionUpdateAvailable) {
          setState(() {
            _versionCheckComplete = true;
            _pendingVersionState = state;
          });
          _checkAndProceed();
        } else if (state is AppVersionNetworkError && state.retryCount > 3) {
          setState(() {
            _versionCheckComplete = true;
            _pendingVersionState = state;
          });
          _checkAndProceed();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Deep Atmosphere Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 70, 45, 1), // Sedikit lebih gelap
                    Color.fromRGBO(
                        1, 101, 65, 1), // Sama dengan header home page
                    Color.fromRGBO(
                        0, 80, 52, 1), // Sedikit lebih gelap untuk base
                  ],
                ),
              ),
            ),

            // 2. Animated Gold Particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _GoldParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // 3. Glowing Moon (Top Right)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * 0.08,
                  right: MediaQuery.of(context).size.width * 0.08,
                  child: FadeTransition(
                    opacity: _fadeInElements,
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: _CrescentMoonPainter(
                        glowIntensity: _pulseController.value,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 4. Parallax Mosque Silhouette (Multi-layered)
            AnimatedBuilder(
              animation: _mosqueRise,
              builder: (context, _) {
                return Positioned(
                  bottom: -_mosqueRise.value * 0.5, // Parallax effect
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Opacity(
                    opacity: 0.3,
                    child: CustomPaint(
                      painter: _MosqueLayerPainter(layer: 1),
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _mosqueRise,
              builder: (context, _) {
                return Positioned(
                  bottom: -_mosqueRise.value,
                  left: 0,
                  right: 0,
                  height: 180,
                  child: CustomPaint(
                    painter: _MosqueLayerPainter(layer: 2),
                  ),
                );
              },
            ),

            // 5. Hanging Lanterns
            _buildHangingLantern(
              left: MediaQuery.of(context).size.width * 0.1,
              height: 120,
              delay: 0.0,
            ),
            _buildHangingLantern(
              left: MediaQuery.of(context).size.width * 0.85,
              height: 100,
              delay: 0.5,
            ),

            // 6. Main Content (Centered)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 100), // Adjusted for keyboard/layout
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: Image.asset(
                              'assets/images/ic_launcher.png',
                              width: 110,
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // "HABA" Text with Slide-in + Fade
                    AnimatedBuilder(
                      animation: _textSlide,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: const Text(
                              'HABA',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 8,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // "Ramadhan Mubarak" with Gold Shimmer
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFade.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  Color(0xFFC6A664), // Dark Gold
                                  Color(0xFFFFD700), // Bright Gold
                                  Color(0xFFC6A664), // Dark Gold
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                transform: GradientRotation(
                                  _shimmerController.value * 2 * math.pi,
                                ),
                              ).createShader(bounds);
                            },
                            child: const Text(
                              '✨ Ramadhan Mubarak ✨',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white, // Masked by shader
                                fontFamily: 'Poppins',
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 7. Version/Loading Indicator at very bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _animationComplete ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: BlocBuilder<AppVersionBloc, AppVersionState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        if (state is! AppVersionUpToDate)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          state is AppVersionChecking
                              ? (state.retryCount > 0
                                  ? 'Menghubungkan ulang...'
                                  : 'Memeriksa versi...')
                              : '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHangingLantern(
      {required double left, required double height, required double delay}) {
    return AnimatedBuilder(
      animation: _swingController,
      builder: (context, _) {
        final swing =
            math.sin((_swingController.value + delay) * math.pi * 2) * 0.05;

        return Positioned(
          top: -20, // Start slightly above screen
          left: left,
          child: FadeTransition(
            opacity: _fadeInElements,
            child: Transform.rotate(
              angle: swing,
              alignment: Alignment.topCenter,
              child: CustomPaint(
                size: Size(40, height),
                painter: _LanternPainter(glowIntensity: _pulseController.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== PREMIUM PAINTERS & DATA ====================

class _GoldParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double wobble;

  _GoldParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobble,
  });
}

class _GoldParticlePainter extends CustomPainter {
  final List<_GoldParticle> particles;
  final double progress;

  _GoldParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (var particle in particles) {
      double dy = (particle.y - particle.speed * 0.01) % 1.0;
      if (dy < 0) dy += 1.0;
      particle.y = dy;

      double dx = particle.x +
          math.sin(progress * 2 * math.pi + particle.wobble) * 0.002;

      final offset = Offset(dx * size.width, dy * size.height);
      final opacity =
          particle.opacity * (0.5 + 0.5 * math.sin(progress * math.pi));

      paint.color = const Color(0xFFFFD700).withValues(alpha: opacity);
      canvas.drawCircle(offset, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldParticlePainter oldDelegate) => true;
}

class _CrescentMoonPainter extends CustomPainter {
  final double glowIntensity;

  _CrescentMoonPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Shadow Cutout (to make crescent)
    // Using Path.combine for cleaner cut without BlendMode issues
    final moonPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.95);

    // Re-draw proper crescent path
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));

    final cutPath = Path();
    cutPath.addOval(Rect.fromCircle(
        center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.1),
        radius: radius * 0.9));

    final crescentPath = Path.combine(PathOperation.difference, path, cutPath);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.2 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Draw Glow
    canvas.drawPath(crescentPath, glowPaint);
    // Draw Moon (Crescent only)
    canvas.drawPath(crescentPath, moonPaint);
  }

  @override
  bool shouldRepaint(covariant _CrescentMoonPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}

class _LanternPainter extends CustomPainter {
  final double glowIntensity;

  _LanternPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Rope
    final ropePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(centerX, 0), Offset(centerX, size.height * 0.6), ropePaint);

    // Lantern Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(
        Offset(centerX, size.height * 0.75), size.width * 0.6, glowPaint);

    // Lantern Body
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.8);
    final path = Path();

    final top = size.height * 0.6;
    final mid = size.height * 0.75;
    final bottom = size.height * 0.9;

    path.moveTo(centerX, top);
    path.quadraticBezierTo(centerX + size.width * 0.4, mid, centerX, bottom);
    path.quadraticBezierTo(centerX - size.width * 0.4, mid, centerX, top);
    path.close();

    canvas.drawPath(path, paint);

    // Light Source
    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * glowIntensity);
    canvas.drawCircle(Offset(centerX, mid), 3, lightPaint);
  }

  @override
  bool shouldRepaint(covariant _LanternPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}

class _MosqueLayerPainter extends CustomPainter {
  final int layer;

  _MosqueLayerPainter({required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;

    if (layer == 1) {
      // Layer belakang: siluet bukit/bangunan rendah sebagai latar
      paint.color = const Color(0xFF003323);
      path.moveTo(0, h);
      path.lineTo(0, h * 0.5);
      // Gelombang atap bangunan di kejauhan
      for (double i = 0; i < w; i += 80) {
        path.quadraticBezierTo(i + 40, h * 0.42, i + 80, h * 0.5);
      }
      path.lineTo(w, h);
    } else {
      // Layer depan: siluet masjid utama yang detail
      paint.color = const Color(0xFF002219);
      path.moveTo(0, h);

      // --- Bangunan Sayap Kiri ---
      path.lineTo(0, h * 0.65);
      path.lineTo(w * 0.08, h * 0.65);

      // --- Menara Kiri ---
      path.lineTo(w * 0.08, h * 0.40);
      // Balkon bawah
      path.lineTo(w * 0.06, h * 0.40);
      path.lineTo(w * 0.06, h * 0.38);
      path.lineTo(w * 0.085, h * 0.38);
      // Tiang menara atas
      path.lineTo(w * 0.09, h * 0.28);
      // Balkon atas
      path.lineTo(w * 0.07, h * 0.28);
      path.lineTo(w * 0.07, h * 0.26);
      path.lineTo(w * 0.095, h * 0.26);
      // Kubah menara (kubah kecil meruncing)
      path.quadraticBezierTo(w * 0.10, h * 0.20, w * 0.105, h * 0.14);
      path.quadraticBezierTo(w * 0.11, h * 0.20, w * 0.115, h * 0.26);
      // Turun sisi kanan menara
      path.lineTo(w * 0.14, h * 0.26);
      path.lineTo(w * 0.14, h * 0.28);
      path.lineTo(w * 0.12, h * 0.28);
      path.lineTo(w * 0.125, h * 0.38);
      path.lineTo(w * 0.15, h * 0.38);
      path.lineTo(w * 0.15, h * 0.40);
      path.lineTo(w * 0.13, h * 0.40);
      path.lineTo(w * 0.13, h * 0.65);

      // --- Dinding menuju Kubah Kecil Kiri ---
      path.lineTo(w * 0.20, h * 0.65);
      path.lineTo(w * 0.20, h * 0.55);

      // --- Kubah Kecil Kiri (Onion Dome) ---
      _drawOnionDome(path, w * 0.20, h * 0.55, w * 0.14, h * 0.20);

      path.lineTo(w * 0.34, h * 0.55);
      path.lineTo(w * 0.34, h * 0.48);

      // --- Kubah Utama Besar (Onion Dome) ---
      _drawOnionDome(path, w * 0.34, h * 0.48, w * 0.32, h * 0.38);

      // --- Dinding menuju Kubah Kecil Kanan ---
      path.lineTo(w * 0.66, h * 0.48);
      path.lineTo(w * 0.66, h * 0.55);

      // --- Kubah Kecil Kanan (Onion Dome) ---
      _drawOnionDome(path, w * 0.66, h * 0.55, w * 0.14, h * 0.20);

      path.lineTo(w * 0.80, h * 0.55);
      path.lineTo(w * 0.80, h * 0.65);

      // --- Menara Kanan ---
      path.lineTo(w * 0.87, h * 0.65);
      path.lineTo(w * 0.87, h * 0.40);
      // Balkon bawah
      path.lineTo(w * 0.85, h * 0.40);
      path.lineTo(w * 0.85, h * 0.38);
      path.lineTo(w * 0.875, h * 0.38);
      // Tiang menara atas
      path.lineTo(w * 0.88, h * 0.28);
      // Balkon atas
      path.lineTo(w * 0.86, h * 0.28);
      path.lineTo(w * 0.86, h * 0.26);
      path.lineTo(w * 0.885, h * 0.26);
      // Kubah menara (kubah kecil meruncing)
      path.quadraticBezierTo(w * 0.89, h * 0.20, w * 0.895, h * 0.14);
      path.quadraticBezierTo(w * 0.90, h * 0.20, w * 0.905, h * 0.26);
      // Turun sisi kanan menara
      path.lineTo(w * 0.93, h * 0.26);
      path.lineTo(w * 0.93, h * 0.28);
      path.lineTo(w * 0.91, h * 0.28);
      path.lineTo(w * 0.915, h * 0.38);
      path.lineTo(w * 0.94, h * 0.38);
      path.lineTo(w * 0.94, h * 0.40);
      path.lineTo(w * 0.92, h * 0.40);
      path.lineTo(w * 0.92, h * 0.65);

      // --- Bangunan Sayap Kanan ---
      path.lineTo(w, h * 0.65);
      path.lineTo(w, h);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Menggambar kubah bawang (onion dome) khas arsitektur masjid
  void _drawOnionDome(
      Path path, double startX, double startY, double width, double height) {
    final endX = startX + width;
    final topY = startY - height;
    final midX = startX + width / 2;

    // Sisi kiri kubah: mengembang sedikit keluar, lalu meruncing ke puncak
    path.cubicTo(
      startX - width * 0.12,
      startY - height * 0.4,
      midX - width * 0.12,
      topY + height * 0.15,
      midX,
      topY,
    );

    // Sisi kanan kubah: berlawanan simetris
    path.cubicTo(
      midX + width * 0.12,
      topY + height * 0.15,
      endX + width * 0.12,
      startY - height * 0.4,
      endX,
      startY,
    );
  }

  @override
  bool shouldRepaint(covariant _MosqueLayerPainter oldDelegate) => false;
}
