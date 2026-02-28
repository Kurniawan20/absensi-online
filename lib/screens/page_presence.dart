import 'dart:math' show min;
import 'dart:async';
import 'dart:convert';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring_project/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './page_login.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/custom_alert.dart';
import '../widgets/security_alert.dart';
import '../services/attendance_service.dart';
import '../services/security_service.dart';
import '../services/attendance_reminder_service.dart';
import '../utils/storage_config.dart';
import '../constants/office_location_config.dart' hide OfficeLocation;
import '../constants/attendance_response_codes.dart';
import '../models/office_location.dart';

void main() => runApp(const Presence());

class Presence extends StatefulWidget {
  const Presence({super.key});

  @override
  State<Presence> createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  SharedPreferences? preferences;
  Timer? timer;

  bool isJailBroken = false;
  bool canMockLocation = false;
  bool isRealDevice = true;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;

  // Office locations (multiple)
  List<OfficeLocation> officeLocations = [];

  // Index lokasi kantor yang sedang ditampilkan di map
  int _currentLocationIndex = 0;

  // Zoom level untuk map
  double zoomVar = 17.0;

  LatLng currentLatLng = LatLng(
    OfficeLocationConfig.defaultLatitude,
    OfficeLocationConfig.defaultLongitude,
  );

  String? _selectedOption;
  bool _isSwipeEnabled = false;
  double _slideValue = 0.0;
  bool _isSliding = false;

  Timer? _timer;
  String _currentTime = '';
  String? _jamMasuk;
  String? _jamPulang;

  static const bool _securityValidationEnabled = true;

  final _attendanceService = AttendanceService();
  final _securityService = SecurityService();
  final _reminderService = AttendanceReminderService();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) => _updateTime());
    initializePreference().then((result) {
      if (!mounted) return;
      setState(() {});
    });

    // Initialize reminder service
    _reminderService.initialize();

    // Schedule daily 17:00 checkout reminder (temporarily set to 11:10 for testing)
    _reminderService.scheduleDailyCheckOutReminder(hour: 11, minute: 10);

    getUserCurrentLocation().then((currLocation) {
      if (!mounted) return;
      setState(() {
        currentLatLng = LatLng(currLocation.latitude, currLocation.longitude);
        if (_controller.isCompleted) {
          _controller.future.then((controller) {
            if (!mounted) return;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: currentLatLng, zoom: zoomVar),
              ),
            );
          });
        }
      });
    });

    _loadAttendanceData();
    _performSecurityCheck();
  }

  Future<void> initializePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load locations dari SharedPreferences
      final locationsJson = prefs.getString('office_locations');
      if (locationsJson != null && locationsJson.isNotEmpty) {
        officeLocations = OfficeLocation.fromJsonString(locationsJson);
        print('Loaded ${officeLocations.length} office location(s):');
        for (var loc in officeLocations) {
          print(
              '  - ${loc.nama}: (${loc.latitude}, ${loc.longitude}), radius: ${loc.radius}m');
        }
      } else {
        print('No office locations found in SharedPreferences');
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('Error initializing preferences: $e');
    }
  }

  final Completer<GoogleMapController> _controller = Completer();

  Future<Position> getUserCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showDialog(
          context: context,
          builder: (context) => CustomAlert(
            title: 'Peringatan',
            message: 'Mohon izikan akses lokasi untuk melakukan absensi',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
          ),
        );
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      showDialog(
        context: context,
        builder: (context) => CustomAlert(
          title: 'Peringatan',
          message: 'Mohon izikan akses lokasi untuk melakukan absensi',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
        ),
      );
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  late GoogleMapController mapController;
  final bool _inRadius = true;

  void _checkRadius(String type) async {
    try {
      // Perform security check before attendance
      final securityResult = await _securityService.performSecurityCheck();
      if (!securityResult.isSecure) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SecurityAlert(
            title: 'Absensi Diblokir',
            message:
                'Absensi tidak dapat dilakukan karena perangkat tidak memenuhi persyaratan keamanan.',
            violations: securityResult.violations,
            canDismiss: true,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomLoadingAlert(
          message: type == 'absenmasuk'
              ? 'Memproses Absen Masuk'
              : 'Memproses Absen Pulang',
        ),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check for fake GPS / mock location
      if (position.isMocked) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SecurityAlert(
            title: 'Absensi Diblokir',
            message:
                'Absensi tidak dapat dilakukan karena terdeteksi penggunaan lokasi palsu (Fake GPS).',
            violations: [
              'Fake GPS / Mock Location terdeteksi',
              'Lokasi tidak berasal dari GPS asli perangkat',
            ],
            canDismiss: true,
          ),
        );
        return;
      }

      // Calculate distance to all locations and find the closest one
      double minDistance = double.infinity;

      for (var location in officeLocations) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
        }
      }

      // Check if within any office radius
      final isWithinRadius = officeLocations.any((location) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        return distance <= location.radius;
      });

      if (isWithinRadius) {
        _absen(position.latitude, position.longitude, type);
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorBottomSheet(
          context,
          'Lokasi Invalid',
          'Anda berada di luar area kantor',
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorBottomSheet(
        context,
        'Gagal',
        'Terjadi kesalahan. Silahkan coba lagi.',
      );
    }
  }

  void _fetchData(BuildContext context) async {
    // Removed duplicate loading dialog since it's now shown in _checkRadius
  }

  void _showSuccessBottomSheet(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (bottomSheetContext) {
        // Auto-dismiss setelah 2 detik
        Future.delayed(const Duration(seconds: 2), () {
          try {
            if (mounted &&
                Navigator.of(bottomSheetContext, rootNavigator: true)
                    .canPop()) {
              Navigator.of(bottomSheetContext, rootNavigator: true).pop();
            }
          } catch (_) {
            // Bottom sheet sudah di-dismiss manual oleh user
          }
        });

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (animContext, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 101, 65, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color.fromRGBO(1, 101, 65, 1),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Berhasil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showErrorBottomSheet(
    BuildContext context,
    String title,
    String message, {
    IconData? icon,
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.red.shade600;
    final effectiveIcon = icon ?? Icons.warning_amber_rounded;
    final backgroundColor = color?.withValues(alpha: 0.1) ?? Colors.red.shade50;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (animContext, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(effectiveIcon, color: effectiveColor, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(bottomSheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<String> _absen(double lat, double long, String absenType) async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getString("kode_kantor").toString();
    final nrk = prefs.getString("npp");
    final deviceId = prefs.getString("device_id");

    print('=== Starting attendance process ===');
    print('Type: $absenType');
    print('Location: lat=$lat, long=$long');
    print('Branch ID: $branchId');
    print('NRK: $nrk');
    print('Device ID: $deviceId');

    try {
      final storage = StorageConfig.secureStorage;
      var token = await storage.read(key: 'auth_token');

      print('\n=== Token Check ===');
      print('Raw token: ${token ?? "null"}');

      if (token == null) {
        print('Token is null, checking all stored items:');
        final allItems = await storage.readAll();
        print('All stored items: $allItems');

        Navigator.of(context, rootNavigator: true).pop(context);
        _showErrorBottomSheet(
          context,
          'Session Expired',
          'Sesi anda telah berakhir. Silakan login kembali.',
        );

        // Redirect to login
        Future.delayed(Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()),
            (route) => false,
          );
        });

        return "token expired";
      }

      // Check if user is within office radius
      if (!_inRadius) {
        Navigator.of(context, rootNavigator: true).pop(context);
        _showErrorBottomSheet(
          context,
          'Lokasi Invalid',
          'Anda berada diluar radius kantor!',
        );
        return "absen gagal";
      }

      // Proceed with attendance request directly (without checksession)
      try {
        print('\n=== Making attendance request ===');
        print('URL: ${ApiConstants.baseUrl}/$absenType');
        print(
          'Headers: Authorization: Bearer ${token.substring(0, min(10, token.length))}...',
        );
        print('Body: {');
        print('  "npp": "$nrk",');
        print('  "latitude": "$lat",');
        print('  "longitude": "$long",');
        print('  "branch_id": "$branchId"');
        print('}');

        final attendanceUrl = absenType == 'absenmasuk'
            ? ApiConstants.attendanceCheckIn
            : ApiConstants.attendanceCheckOut;

        final getResult = await http
            .post(
              Uri.parse(attendanceUrl),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(<String, String>{
                'npp': nrk.toString(),
                'latitude': lat.toString(),
                'longitude': long.toString(),
                'branch_id': branchId,
              }),
            )
            .timeout(const Duration(seconds: 20));

        print('Attendance response status: ${getResult.statusCode}');
        print('Attendance response body: ${getResult.body}');

        String result = getResult.body.toString().replaceAll('""', "");
        final responseData = jsonDecode(result);
        final String rcode = responseData['rcode'] ?? '';
        final String? apiMessage = responseData['message'];

        // Extract is_late from API response data
        final Map<String, dynamic>? apiData = responseData['data'];
        final bool isLateFromApi =
            apiData?['is_late'] == true || apiData?['is_late'] == 1;
        final String? batasJamMasuk = apiData?['batas_jam_masuk'];

        // Get response based on type (check-in or check-out)
        // For success (rcode == '00'), use our custom messages instead of API messages
        final AttendanceResponse response = absenType == 'absenmasuk'
            ? AttendanceResponseCodes.getCheckInResponse(
                rcode,
                rcode == '00' ? null : apiMessage,
              )
            : AttendanceResponseCodes.getCheckOutResponse(
                rcode,
                rcode == '00' ? null : apiMessage,
              );

        if (response.isSuccess) {
          // Update attendance time immediately after successful check-in/out
          final now = DateTime.now();
          final currentTime =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          await _attendanceService.updateAttendanceTime(
            absenType,
            currentTime,
          );

          // Update local state
          setState(() {
            if (absenType == 'absenmasuk') {
              _jamMasuk = currentTime;
            } else {
              _jamPulang = currentTime;
            }
          });

          // Handle reminder notifications (wrapped in try-catch to not break success flow)
          try {
            if (absenType == 'absenmasuk') {
              // Schedule check-out reminder after successful check-in
              await _reminderService.scheduleCheckOutReminder(
                checkInTime: now,
                workHours: 8, // 8 jam kerja
              );
              print('✅ Check-out reminder scheduled');
            } else if (absenType == 'absenpulang') {
              // Cancel reminders after successful check-out
              await _reminderService.cancelCheckOutReminders();
              print('✅ Check-out reminders cancelled');
            }
          } catch (reminderError) {
            // Log but don't fail the attendance flow
            print(
              '⚠️ Reminder scheduling failed (non-critical): $reminderError',
            );
          }

          // Close loading modal first
          Navigator.of(context, rootNavigator: true).pop(context);

          // Show success bottom sheet with late status from API
          final successTitle = absenType == 'absenmasuk' && isLateFromApi
              ? 'Terlambat'
              : response.title;
          final successMessage = absenType == 'absenmasuk'
              ? _getCheckInMessage(isLateFromApi, batasJamMasuk)
              : response.message;
          _showSuccessBottomSheet(
            context,
            '$successTitle\n$successMessage',
          );

          // Trigger attendance update notification
          _attendanceService.notifyListeners();

          // Refresh data from API after successful check-in/out
          _loadAttendanceData();

          return "absen berhasil";
        } else {
          // Handle error responses
          Navigator.of(context, rootNavigator: true).pop(context);

          IconData errorIcon;
          Color errorColor;

          switch (response.icon) {
            case AttendanceIcon.tooEarly:
              errorIcon = Icons.access_time_rounded;
              errorColor = Colors.orange;
              break;
            case AttendanceIcon.duplicate:
            case AttendanceIcon.warning:
              errorIcon = Icons.warning_amber_rounded;
              errorColor = Colors.orange;
              break;
            default:
              errorIcon = Icons.error_outline;
              errorColor = Colors.red;
          }

          _showErrorBottomSheet(
            context,
            response.title,
            response.message,
            icon: errorIcon,
            color: errorColor,
          );
          return "absen gagal";
        }
      } on TimeoutException catch (e) {
        print('\n=== Attendance request timeout ===');
        print('Error: $e');
        Navigator.of(context, rootNavigator: true).pop(context);
        _showErrorBottomSheet(
          context,
          'Timeout',
          'Koneksi timeout, silahkan coba lagi!',
        );
        return "absen gagal";
      } catch (e) {
        print('\n=== Attendance request error ===');
        print('Error: $e');
        Navigator.of(context, rootNavigator: true).pop(context);
        _showErrorBottomSheet(
          context,
          'Error',
          'Terjadi kesalahan, silahkan coba lagi!',
        );
        return "absen gagal";
      }
    } catch (e) {
      print('\n=== Unexpected error ===');
      print('Error: $e');
      Navigator.of(context, rootNavigator: true).pop(context);
      _showErrorBottomSheet(
        context,
        'Error',
        'Terjadi kesalahan, silahkan coba lagi!',
      );
      return "absen gagal";
    }
  }

  bool _isWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  String _getCheckInMessage(bool isLate, String? batasJamMasuk) {
    // Weekend exception: Different message for weekend attendance
    if (_isWeekend()) {
      return 'Absensi weekend berhasil dicatat. Terima kasih atas kerja keras Anda!';
    }

    if (isLate) {
      final batasInfo = batasJamMasuk != null ? ' (Batas: $batasJamMasuk)' : '';
      return 'Anda terlambat melakukan absensi$batasInfo. Harap segera memberikan keterangan keterlambatan.';
    } else {
      return 'Absensi berhasil dilakukan tepat waktu. Selamat bekerja!';
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final data = await _attendanceService.getTodayAttendance();
      if (mounted && data['success']) {
        setState(() {
          _jamMasuk = data['check_in_time'];
          _jamPulang = data['check_out_time'];
        });
      }
    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  Future<void> _performSecurityCheck() async {
    // Skip security check if validation is disabled
    if (!_securityValidationEnabled) {
      print('Security validation is disabled');
      return;
    }

    try {
      print('Performing security check...');
      final securityResult = await _securityService.performSecurityCheck();

      if (!securityResult.isSecure) {
        print('Security violations detected: ${securityResult.violations}');

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => SecurityAlert(
              title: 'Peringatan Keamanan',
              message:
                  'Aplikasi tidak dapat digunakan karena perangkat tidak memenuhi persyaratan keamanan.',
              violations: securityResult.violations,
              onPressed: () {
                Navigator.of(context).pop();
                // Exit the app or navigate back to login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
            ),
          );
        }
      } else {
        print('Security check passed: Device is secure');
      }
    } catch (e) {
      print('Security check error: $e');
      // In case of error, show warning but allow usage
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomAlert(
            title: 'Peringatan',
            message:
                'Tidak dapat memverifikasi keamanan perangkat. Pastikan perangkat Anda memenuhi persyaratan keamanan.',
            icon: Icons.warning,
            iconColor: Colors.orange,
          ),
        );
      }
    }
  }

  void signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }

  String googleApikey = "GOOGLE_MAP_API_KEY";
  LatLng startLocation = LatLng(27.6602292, 85.308027);

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final GoogleMapController controller = await _controller.future;
      final latLng = LatLng(position.latitude, position.longitude);

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17.0),
        ),
      );

      setState(() {
        currentLatLng = latLng;
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not get current location. Please check your location permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigasi ke lokasi kantor berikutnya (cyclic)
  Future<void> _zoomToOffice() async {
    if (officeLocations.isEmpty) {
      print('No office locations available to zoom to');
      return;
    }

    try {
      final GoogleMapController controller = await _controller.future;
      final location = officeLocations[_currentLocationIndex];
      final latLng = LatLng(location.latitude, location.longitude);

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17.0),
        ),
      );

      setState(() {
        currentLatLng = latLng;
        // Pindah ke lokasi berikutnya untuk tap selanjutnya
        _currentLocationIndex =
            (_currentLocationIndex + 1) % officeLocations.length;
      });
    } catch (e) {
      print('Error zooming to office: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat memperbesar ke lokasi kantor.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Kehadiran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map taking space between app bar and bottom sheet
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.48,
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: currentLatLng,
                    zoom: zoomVar,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  circles: Set.from(
                    officeLocations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final location = entry.value;
                      return Circle(
                        circleId: CircleId('office_$index'),
                        center: LatLng(location.latitude, location.longitude),
                        radius: location.radius,
                        fillColor: Color.fromRGBO(1, 101, 65, 0.2),
                        strokeColor: Color.fromRGBO(1, 101, 65, 0.5),
                        strokeWidth: 2,
                      );
                    }).toList(),
                  ),
                  markers: Set.from(
                    officeLocations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final location = entry.value;
                      return Marker(
                        markerId: MarkerId('office_marker_$index'),
                        position: LatLng(location.latitude, location.longitude),
                        infoWindow: InfoWindow(
                          title: location.nama,
                          snippet:
                              '${location.alamat}\nRadius: ${location.radius.toStringAsFixed(0)}m',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(120.0),
                      );
                    }).toList(),
                  ),
                ),

                // Location status badge
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: StreamBuilder<Position>(
                    stream: Geolocator.getPositionStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox();

                      final userPosition = snapshot.data!;

                      // Calculate distance to all locations and find the closest one
                      double minDistance = double.infinity;
                      OfficeLocation? closestLocation;

                      for (var location in officeLocations) {
                        final distance = Geolocator.distanceBetween(
                          userPosition.latitude,
                          userPosition.longitude,
                          location.latitude,
                          location.longitude,
                        );
                        if (distance < minDistance) {
                          minDistance = distance;
                          closestLocation = location;
                        }
                      }

                      // Check if user is within any office radius
                      final bool isOutsideRadius = closestLocation == null ||
                          minDistance > closestLocation.radius;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isOutsideRadius
                                  ? Colors.red[400]
                                  : Colors.green[400],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutsideRadius
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isOutsideRadius
                                      ? 'Di Luar Area Kantor'
                                      : 'Di Dalam Area Kantor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ), // End Location status badge Container
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Custom map buttons - positioned at bottom right of map
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.48 + 16,
            right: 16,
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.business, size: 20),
                      onPressed: _zoomToOffice,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Tombol navigasi ke lokasi kantor berikutnya
                  if (officeLocations.length > 1) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(1, 101, 65, 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentLocationIndex + 1}/${officeLocations.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.my_location, size: 20),
                      onPressed: _getCurrentLocation,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with attendance info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.48,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First Card (Date and Absen Masuk/Pulang)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      children: [
                        // Date and Time Display
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                _currentTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Absen Masuk/Pulang Status
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              // Absen Masuk
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: _jamMasuk != '--:--'
                                            ? Color.fromRGBO(1, 101, 65, 0.1)
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _jamMasuk != '--:--'
                                              ? FluentIcons
                                                  .checkmark_circle_48_regular
                                              : FluentIcons.dismiss_24_filled,
                                          color: _jamMasuk != '--:--'
                                              ? Color.fromRGBO(1, 101, 65, 1)
                                              : Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Absen Masuk',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _jamMasuk ?? '--:--',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 13,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Center Icon
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.calendar_month_sharp,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                              ),
                              // Absen Pulang
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Absen Pulang',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _jamPulang ?? '--:--',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 13,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: _jamPulang != '--:--'
                                            ? Color.fromRGBO(1, 101, 65, 0.1)
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _jamPulang != '--:--'
                                              ? FluentIcons
                                                  .checkmark_circle_48_regular
                                              : FluentIcons.dismiss_24_filled,
                                          color: _jamPulang != '--:--'
                                              ? Color.fromRGBO(1, 101, 65, 1)
                                              : Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Second Card (Presence Options)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 1,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          child: Text(
                            'Silahkan pilih jenis Absensi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Attendance Options
                        Center(
                          child: Container(
                            width: 200,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAttendanceOption(
                                  'Absen Masuk',
                                  Theme.of(context).primaryColor,
                                  () {
                                    setState(() {
                                      _selectedOption = 'Absen Masuk';
                                      _isSwipeEnabled = true;
                                    });
                                  },
                                  _selectedOption == 'Absen Masuk',
                                ),
                                SizedBox(height: 10),
                                _buildAttendanceOption(
                                  'Absen Pulang',
                                  Theme.of(context).primaryColor,
                                  () {
                                    setState(() {
                                      _selectedOption = 'Absen Pulang';
                                      _isSwipeEnabled = true;
                                    });
                                  },
                                  _selectedOption == 'Absen Pulang',
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Swipe to Absen Masuk
                        if (_selectedOption != null)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background Track
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(seconds: 2),
                                      builder: (context, value, child) {
                                        return ShaderMask(
                                          shaderCallback: (rect) {
                                            return LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Theme.of(
                                                  context,
                                                ).primaryColor.withValues(alpha: 0.5),
                                                Theme.of(context).primaryColor,
                                                Theme.of(
                                                  context,
                                                ).primaryColor.withValues(alpha: 0.5),
                                              ],
                                              stops: [
                                                value - 0.2,
                                                value,
                                                value + 0.2,
                                              ],
                                            ).createShader(rect);
                                          },
                                          child: Text(
                                            _selectedOption == 'Absen Masuk'
                                                ? 'Geser ke kanan >>>'
                                                : 'Geser ke kanan >>>',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        );
                                      },
                                      onEnd: () {
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                ),

                                // Active Fill
                                Container(
                                  height: 60,
                                  width: 60.0 + _slideValue,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.15),
                                  ),
                                ),

                                // Slider Knob
                                if (_isSwipeEnabled)
                                  AnimatedPositioned(
                                    duration: Duration(
                                      milliseconds: _isSliding ? 0 : 300,
                                    ),
                                    curve: Curves.elasticOut,
                                    left: _slideValue,
                                    child: GestureDetector(
                                      onHorizontalDragUpdate: (details) {
                                        setState(() {
                                          _isSliding = true;
                                          final maxWidth = MediaQuery.of(
                                                context,
                                              ).size.width -
                                              24 -
                                              60;
                                          _slideValue =
                                              (_slideValue + details.delta.dx)
                                                  .clamp(0.0, maxWidth);
                                        });
                                      },
                                      onHorizontalDragEnd: (details) {
                                        final maxWidth =
                                            MediaQuery.of(context).size.width -
                                                24 -
                                                60;
                                        final threshold = maxWidth * 0.7;

                                        if (_slideValue > threshold) {
                                          _checkRadius(
                                            _selectedOption == 'Absen Masuk'
                                                ? 'absenmasuk'
                                                : 'absenpulang',
                                          );
                                          _fetchData(context);
                                        }

                                        setState(() {
                                          _isSliding = false;
                                          _slideValue = 0;
                                        });
                                      },
                                      child: Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context).primaryColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: Offset(2, 2),
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    left: 0,
                                    child: Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                      ),
                                      child: Icon(
                                        Icons.lock,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Stack(
                            children: [
                              Container(
                                height: 48,
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 48),
                                    Expanded(
                                      child: Text(
                                        'Pilih opsi di atas',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 48),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: -2,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOption(
    String title,
    Color color,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? color : Colors.transparent,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PresenceGeo extends GeolocatorPlatform {}
