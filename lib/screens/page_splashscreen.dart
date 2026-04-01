import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;

  bool _animationComplete = false;
  bool _versionCheckComplete = false;
  AppVersionState? _pendingVersionState;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

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

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _startAppFlow();
    _startVersionCheck();
  }

  void _startAppFlow() async {
    _mainController.forward();

    // Minimum Splash Duration
    await Future.delayed(const Duration(milliseconds: 1500));

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

            // 2. Default Clean Background
            // Ramadhan ornaments have been removed

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
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Image.asset(
                                'assets/images/ic_launcher.png',
                                fit: BoxFit.contain,
                              ),
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

                    // Ramadhan Mubarak Text removed for Default Theme
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

}

// (Premium Painters and Data classes removed for default theme)
