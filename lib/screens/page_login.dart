import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/login/login_event.dart';
import '../bloc/login/login_state.dart';
import '../widget/dialogs.dart';
import './main_layout.dart';
import '../services/biometric_service.dart';
import '../services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/storage_config.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  static const String id = 'login';

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController txtEditEmail = TextEditingController();
  final TextEditingController txtEditPwd = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();
  final BiometricService _biometricService = BiometricService();
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _passwordVisible = false;
  String _androidId = 'Unknown';
  Position? _currentPosition;
  bool _isBiometricAvailable = false;
  bool _showBiometricButton = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _initAndroidId();
    await _getUserCurrentLocation();
    await _initializeBiometric();
    context.read<LoginBloc>().add(InitializeLoginData());
  }

  Future<void> _initializeBiometric() async {
    print('Initializing biometric...');
    final isBiometricAvailable = await _biometricService.isBiometricAvailable();
    final biometrics = await _biometricService.getAvailableBiometrics();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final credentials = await _secureStorage.getCredentials();

    print('Biometric check:');
    print('- Available: $isBiometricAvailable');
    print('- Biometrics: $biometrics');
    print('- Enabled: $isEnabled');
    print('- Has credentials: ${credentials != null}');

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isBiometricAvailable && biometrics.isNotEmpty;
        _biometricEnabled = isEnabled;
        // Only show button if biometric is both available and enabled
        _showBiometricButton =
            _isBiometricAvailable && isEnabled && credentials != null;
      });
    }

    // Add listener to email field after initialization
    txtEditEmail.addListener(_onEmailChanged);
  }

  void _onEmailChanged() async {
    if (!_isBiometricAvailable || !_biometricEnabled) {
      setState(() => _showBiometricButton = false);
      return;
    }

    final credentials = await _secureStorage.getCredentials();
    if (credentials == null) {
      setState(() => _showBiometricButton = false);
      return;
    }

    final showButton =
        txtEditEmail.text.isEmpty || credentials['email'] == txtEditEmail.text;
    print('Email check:');
    print('- Current email: ${txtEditEmail.text}');
    print('- Stored email: ${credentials['email']}');
    print('- Show button: $showButton');

    setState(() => _showBiometricButton = showButton);
  }

  @override
  void dispose() {
    txtEditEmail.removeListener(_onEmailChanged);
    txtEditEmail.dispose();
    txtEditPwd.dispose();
    super.dispose();
  }

  Future<void> _initAndroidId() async {
    try {
      if (Platform.isAndroid) {
        _androidId = await AndroidId().getId() ?? 'Unknown ID';
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        _androidId = iosInfo.identifierForVendor ?? 'Unknown ID';
      }
    } on PlatformException {
      _androidId = 'Failed to get Device ID';
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _getUserCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle denied permission without showing alert
          print('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Handle permanently denied permission without showing alert
        print('Location permission permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _showDialogWarning(String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Gagal!', style: TextStyle(color: Colors.black)),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _fireToast(String message, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.green.shade900,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _validateInputs({bool isBiometricLogin = false}) {
    final formState = _formKey.currentState;
    if (formState == null) {
      _fireToast('Terjadi kesalahan pada form', isError: true);
      return;
    }

    if (!formState.validate()) {
      return;
    }

    formState.save();
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: txtEditEmail.text.trim(),
            password: txtEditPwd.text,
            deviceId: _androidId,
            isBiometricLogin: isBiometricLogin,
          ),
        );
  }

  void _toggleObscured() {
    setState(() {
      _passwordVisible = !_passwordVisible;
      if (textFieldFocusNode.hasPrimaryFocus) return;
      textFieldFocusNode.canRequestFocus = false;
    });
  }

  Future<void> _authenticateWithBiometric() async {
    print('Starting biometric authentication...');

    try {
      print('Checking biometric availability...');
      final isBiometricAvailable =
          await _biometricService.isBiometricAvailable();
      print('Biometric available: $isBiometricAvailable');

      if (!isBiometricAvailable) {
        print('Biometric not available');
        _fireToast(
            'Please enable fingerprint authentication in your device settings');
        return;
      }

      print('Getting stored credentials...');
      final credentials = await _secureStorage.getCredentials();
      if (credentials == null) {
        print('No stored credentials found');
        _fireToast('Please login manually first to enable fingerprint login');
        return;
      }

      print('Attempting biometric authentication...');
      final isAuthenticated = await _biometricService.authenticate();
      print('Authentication result: $isAuthenticated');

      if (!isAuthenticated) {
        print('Authentication failed or was cancelled');
        return; // Don't show toast here as the system will show its own dialog
      }

      if (!mounted) return;

      print('Setting credentials and triggering login...');
      setState(() {
        txtEditEmail.text = credentials['email'] ?? '';
        txtEditPwd.text = credentials['password'] ?? '';
      });

      // Small delay to ensure UI updates
      await Future.delayed(Duration(milliseconds: 100));

      if (!mounted) return;

      // Trigger login with biometric flag
      _validateInputs(isBiometricLogin: true);
    } on PlatformException catch (e) {
      print('Platform error during authentication: ${e.toString()}');
      String message;
      switch (e.code) {
        case 'NotAvailable':
          message =
              'Fingerprint authentication is not available on this device';
          break;
        case 'NotEnrolled':
          message =
              'Please set up fingerprint authentication in your device settings';
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = 'Authentication error. Please try again';
      }
      _fireToast(message);
    } catch (e) {
      print('Error during biometric authentication: $e');
      _fireToast('Authentication error. Please try again');
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    final email = txtEditEmail.text;
    final password = txtEditPwd.text;

    // Save credentials to SharedPreferences for settings page
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);

    // Verify token is stored
    final storage = StorageConfig.secureStorage;
    final token = await storage.read(key: 'auth_token');
    print('\n=== Token Check After Login ===');
    print('Token present: ${token != null}');
    if (token == null) {
      print('Warning: Token not found after login!');
      print('Checking all stored items:');
      final allItems = await storage.readAll();
      print('All stored items: $allItems');
    } else {
      print('Token found with length: ${token.length}');
    }

    // If biometric is enabled, check if we need to update credentials
    final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    if (isBiometricEnabled) {
      final currentCredentials = await _secureStorage.getCredentials();
      final isNewUser = currentCredentials == null || 
                       currentCredentials['email'] != email;
      
      if (isNewUser) {
        print('Updating biometric credentials for new user');
        await _secureStorage.saveCredentials(email, password);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login biometric telah diperbarui'),
              backgroundColor: Color.fromRGBO(1, 101, 65, 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              margin: EdgeInsets.all(10),
            ),
          );
        }
      } else {
        // Still save credentials but don't show message
        await _secureStorage.saveCredentials(email, password);
      }
    }

    // Only show biometric prompt on fresh install
    if (mounted) {
      final isInitialized = await _secureStorage.isAppInitialized();
      final isEnabled = await _secureStorage.isBiometricEnabled();
      final isBiometricAvailable =
          await _biometricService.isBiometricAvailable();
      final biometrics = await _biometricService.getAvailableBiometrics();

      print('Login check:');
      print('- App initialized: $isInitialized');
      print('- Biometric enabled: $isEnabled');
      print('- Biometric available: $isBiometricAvailable');
      print('- Has biometrics: ${biometrics.isNotEmpty}');

      // Only show prompt if:
      // 1. App is not initialized (fresh install)
      // 2. Biometric is available and not already enabled
      if (!isInitialized &&
          !isEnabled &&
          isBiometricAvailable &&
          biometrics.isNotEmpty) {
        // Show prompt to enable biometric
        final shouldEnable = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Aktifkan Login Biometric'),
                  content: const Text(
                      'Perangkat Anda mendukung login dengan Biometric. '
                      'Apakah Anda ingin mengaktifkan fitur ini untuk login lebih cepat?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Tidak'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text(
                        'Aktifkan',
                        style: TextStyle(
                          color: Color.fromRGBO(1, 101, 65, 1),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                );
              },
            ) ??
            false;

        if (shouldEnable) {
          await _secureStorage.setBiometricEnabled(true);
          await _secureStorage.saveCredentials(email, password);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login sidik jari telah diaktifkan'),
                backgroundColor: Color.fromRGBO(1, 101, 65, 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                margin: EdgeInsets.all(10),
              ),
            );
          }
        }
      }
    }

    // Navigate to main layout
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainLayout(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginLoading) {
          print('Login loading state');
          Dialogs.loading(context, GlobalKey<State>(), "Proses...");
        } else if (state is LoginSuccess) {
          print('Login success state');
          // Handle the loading dialog dismissal safely
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          _handleSuccessfulLogin();
        } else if (state is LoginFailure) {
          print('Login failure state: ${state.error}');
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          _fireToast(state.error);
        } else if (state is LoginLocationError) {
          print('Login location error state: ${state.error}');
          _showDialogWarning(state.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // Logo
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          // color: Color.fromRGBO(1, 101, 65, 1),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset("assets/images/ic_launcher.png",
                            height: 50),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Welcome Text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(text: 'Selamat Datang '),
                          TextSpan(text: '👋'),
                          TextSpan(text: '\ndi '),
                          TextSpan(
                            text: 'HABA',
                            style: TextStyle(
                              color: Color.fromRGBO(1, 101, 65, 1),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silahkan masuk untuk melanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Email Field
                    Container(
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color.fromRGBO(1, 101, 65, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextFormField(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'NRK',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 20,
                          ),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 15, right: 10),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: Color.fromRGBO(1, 101, 65, 1),
                              size: 24,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 25,
                            minHeight: 25,
                          ),
                        ),
                        controller: txtEditEmail,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NPP tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    Container(
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color.fromRGBO(1, 101, 65, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextFormField(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Kata Sandi',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 20,
                          ),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 15, right: 10),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: Color.fromRGBO(1, 101, 65, 1),
                              size: 24,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 25,
                            minHeight: 25,
                          ),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Color.fromRGBO(1, 101, 65, 1),
                                size: 24,
                              ),
                              onPressed: _toggleObscured,
                            ),
                          ),
                        ),
                        controller: txtEditPwd,
                        obscureText: !_passwordVisible,
                        enableSuggestions: false,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showGeneralDialog(
                            context: context,
                            pageBuilder: (context, animation1, animation2) =>
                                Container(),
                            transitionBuilder:
                                (context, animation1, animation2, child) {
                              return Transform.scale(
                                scale: Curves.easeInOut
                                    .transform(animation1.value),
                                child: Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 5,
                                          blurRadius: 15,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Hero(
                                          tag: 'forgotPasswordIcon',
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  1, 101, 65, 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(35),
                                            ),
                                            child: const Icon(
                                              Icons.lock_reset_rounded,
                                              size: 35,
                                              color:
                                                  Color.fromRGBO(1, 101, 65, 1),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Lupa Kata Sandi?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        const Text(
                                          'Untuk mengatur ulang kata sandi, silakan hubungi administrator Bank Aceh Syariah atau kunjungi kantor cabang terdekat.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 25),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 45,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromRGBO(
                                                      1, 101, 65, 1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Mengerti',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromRGBO(1, 101, 65, 1),
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        ),
                        child: const Text(
                          'Lupa Kata Sandi?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login Buttons Column
                    Column(
                      children: [
                        // Regular login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _validateInputs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(1, 101, 65, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Fingerprint button (if available)
                        if (_showBiometricButton) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _authenticateWithBiometric,
                              icon: const Icon(
                                Icons.fingerprint,
                                size: 24,
                                color: Color.fromRGBO(1, 101, 65, 1),
                              ),
                              label: const Text(
                                'Masuk dengan Biometric',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromRGBO(1, 101, 65, 1),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color.fromRGBO(1, 101, 65, 1),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Register Text
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        Container(),
                                transitionBuilder:
                                    (context, animation1, animation2, child) {
                                  return Transform.scale(
                                    scale: Curves.easeInOut
                                        .transform(animation1.value),
                                    child: Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              spreadRadius: 5,
                                              blurRadius: 15,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Hero(
                                              tag: 'registerIcon',
                                              child: Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      1, 101, 65, 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(35),
                                                ),
                                                child: const Icon(
                                                  Icons.person_add_rounded,
                                                  size: 35,
                                                  color: Color.fromRGBO(
                                                      1, 101, 65, 1),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              'Daftar Akun Baru',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            const Text(
                                              'Untuk mendaftar akun baru, silakan kunjungi kantor Bank Aceh Syariah terdekat dengan membawa kartu identitas yang masih berlaku.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 25),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 45,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          1, 101, 65, 1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Mengerti',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color.fromRGBO(1, 101, 65, 1),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              ' Daftar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}