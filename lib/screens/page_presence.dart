import 'dart:math' show min;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring_project/screens/Apis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './page_login.dart';
import './home_page.dart';
import './page_rekap_absensi.dart';
import './page_profile.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/custom_alert.dart';
import '../widgets/security_alert.dart';
import '../services/attendance_service.dart';
import '../services/security_service.dart';

void main() => runApp(const Presence());

class Presence extends StatefulWidget {
  const Presence({Key? key}) : super(key: key);

  @override
  _PresenceState createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  bool _isMockLocation = false;
  bool? _jailbroken;
  bool? _developerMode;

  SharedPreferences? preferences;
  Timer? timer;
  double latKantor = 0;
  double longKantor = 0;
  double radius = 0;
  double zoomVar = 17;

  double latKantor2 = 0;
  double longKantor2 = 0;
  double radius2 = 0;
  bool useSecondLocation = false;

  bool isJailBroken = false;
  bool canMockLocation = false;
  bool isRealDevice = true;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;
  LatLng currentLatLng = LatLng(5.543605637891148, 95.32992029020498);

  String? _selectedOption;
  bool _isSwipeEnabled = false;
  double _slideValue = 0.0;
  bool _isSliding = false;

  Timer? _timer;
  String _currentTime = '';
  String? _jamMasuk;
  String? _jamPulang;

  final _attendanceService = AttendanceService();
  final _securityService = SecurityService();

  void initState() {
    super.initState();
    initializeDateFormatting('id', null);

    _timer = Timer.periodic(Duration(minutes: 1), (timer) => _updateTime());
    initializePreference().then((result) {
      if (!mounted) return;
      setState(() {});
    });

    getUserCurrentLocation().then((currLocation) {
      if (!mounted) return;
      setState(() {
        currentLatLng = LatLng(currLocation.latitude, currLocation.longitude);
        if (_controller.isCompleted) {
          _controller.future.then((controller) {
            if (!mounted) return;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: currentLatLng,
                  zoom: zoomVar,
                ),
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
    this.preferences = await SharedPreferences.getInstance();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    latKantor = prefs.getDouble("lat_kantor")!;
    longKantor = prefs.getDouble("long_kantor")!;
    radius = prefs.getDouble("radius")!;

    String? kodeKantor = prefs.getString("kode_kantor");
    if (kodeKantor == "813") {
      latKantor2 = 5.521261515723264;
      longKantor2 = 95.3300600393016;
      radius2 = radius;
      useSecondLocation = true;
    } else if (kodeKantor != null && kodeKantor.startsWith("8")) {
      latKantor2 = 5.544926358826539;
      longKantor2 = 95.31200258268379;
      radius2 = radius;
      useSecondLocation = true;
    }

    if (!mounted) return;
    setState(() {});
  }

  Completer<GoogleMapController> _controller = Completer();

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
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  late GoogleMapController mapController;
  GeolocatorPlatform _geo = new PresenceGeo();
  bool _inRadius = true;

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
            message: 'Absensi tidak dapat dilakukan karena perangkat tidak memenuhi persyaratan keamanan.',
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

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latKantor,
        longKantor,
      );

      if (useSecondLocation) {
        double distanceToSecondOffice = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latKantor2,
          longKantor2,
        );
        distanceInMeters = min(distanceInMeters, distanceToSecondOffice);
      }

      if (distanceInMeters <= radius) {
        _absen(position.latitude, position.longitude, type);
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        showDialog(
          context: context,
          builder: (context) => CustomAlert(
            title: 'Lokasi Invalid',
            message: 'Anda berada di luar area kantor',
            icon: Icons.location_off,
            iconColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (context) => CustomAlert(
          title: 'Gagal',
          message: 'Terjadi kesalahan. Silahkan coba lagi.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        ),
      );
    }
  }

  void _fetchData(BuildContext context, [bool mounted = true]) async {
    // Removed duplicate loading dialog since it's now shown in _checkRadius
  }

  void _fetchDialog(BuildContext context, String message,
      [bool mounted = true]) async {
    showDialog(
      context: context,
      builder: (context) => CustomAlert(
        title: 'Berhasil',
        message: message,
        icon: Icons.check_circle_outline,
        iconColor: Color.fromRGBO(1, 101, 65, 1),
      ),
    );
  }

  void _fetchDialogWarning(BuildContext context, String message,
      [bool mounted = true]) async {
    showDialog(
      context: context,
      builder: (context) => CustomAlert(
        title: 'Peringatan',
        message: message,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.red,
      ),
    );
  }

  void _konfirmasiAbsenPulang(BuildContext context, String message,
      [bool mounted = true]) async {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmAlert(
        title: 'Konfirmasi',
        message: 'Apakah anda yakin akan melakukan absen pulang?',
        onConfirm: () {
          Navigator.pop(context); // Close confirmation dialog
          _fetchDialog(
              context, 'Sedang memproses absen pulang...'); // Show loading
          _checkRadius('absenpulang');
        },
      ),
    );
  }

  Future<String> _absen(double lat, double long, String absenType) async {
    final prefs = await SharedPreferences.getInstance();
    final branch_id = prefs.getString("kode_kantor").toString();
    final nrk = prefs.getString("npp");
    final _deviceId = prefs.getString("device_id");

    print('=== Starting attendance process ===');
    print('Type: $absenType');
    print('Location: lat=$lat, long=$long');
    print('Branch ID: $branch_id');
    print('NRK: $nrk');
    print('Device ID: $_deviceId');

    try {
      final storage = const FlutterSecureStorage();
      var token = await storage.read(key: 'auth_token');

      print('\n=== Token Check ===');
      print('Raw token: ${token ?? "null"}');

      if (token == null) {
        print('Token is null, checking all stored items:');
        final allItems = await storage.readAll();
        print('All stored items: $allItems');

        Navigator.of(context, rootNavigator: true).pop(context);
        showDialog(
          context: context,
          builder: (context) => CustomAlert(
            title: "Session Expired",
            message: "Sesi anda telah berakhir. Silakan login kembali.",
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
          ),
        );

        // Redirect to login
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()),
            (route) => false,
          );
        });

        return "token expired";
      }

      print('\n=== Making check session request ===');
      print('URL: ${ApiConstants.BASE_URL}/checksession');
      print(
          'Headers: Authorization: Bearer ${token.substring(0, min(10, token.length))}...');
      print('Body: {"npp": "$nrk", "deviceId": "$_deviceId"}');

      final checkSessionResult = await http
          .post(Uri.parse(ApiConstants.BASE_URL + "/checksession"),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token'
              },
              body: jsonEncode(<String, String>{
                'npp': nrk.toString(),
                "deviceId": _deviceId.toString(),
              }))
          .timeout(const Duration(seconds: 20));

      print('Check session response status: ${checkSessionResult.statusCode}');
      print('Check session response body: ${checkSessionResult.body}');

      if (checkSessionResult.statusCode != 200) {
        print(
            'Check session failed with status: ${checkSessionResult.statusCode}');
        throw Exception('Check session failed');
      }

      final checkSessionData =
          jsonDecode(checkSessionResult.body.toString().replaceAll('""', ""));

      if (checkSessionData['rcode'] == "00") {
        // Verify token is still valid after check session
        token = await storage.read(key: 'auth_token');
        if (token == null) {
          throw Exception('Token lost after check session');
        }
        if (this._inRadius) {
          try {
            print('\n=== Making attendance request ===');
            print('URL: ${ApiConstants.BASE_URL}/$absenType');
            print(
                'Headers: Authorization: Bearer ${token.substring(0, min(10, token.length))}...');
            print('Body: {');
            print('  "npp": "$nrk",');
            print('  "latitude": "$lat",');
            print('  "longitude": "$long",');
            print('  "branch_id": "$branch_id"');
            print('}');

            final getResult = await http
                .post(Uri.parse(ApiConstants.BASE_URL + "/" + absenType),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                      'Authorization': 'Bearer $token'
                    },
                    body: jsonEncode(<String, String>{
                      'npp': nrk.toString(),
                      'latitude': lat.toString(),
                      'longitude': long.toString(),
                      'branch_id': branch_id
                    }))
                .timeout(const Duration(seconds: 20));

            print('Attendance response status: ${getResult.statusCode}');
            print('Attendance response body: ${getResult.body}');

            String result = getResult.body.toString().replaceAll('""', "");

            if (jsonDecode(result)['rcode'] == "00") {
              // Update attendance time immediately after successful check-in/out
              final now = DateTime.now();
              final currentTime =
                  "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              await _attendanceService.updateAttendanceTime(
                  absenType, currentTime);

              // Update local state
              setState(() {
                if (absenType == 'absenmasuk') {
                  _jamMasuk = currentTime;
                } else {
                  _jamPulang = currentTime;
                }
              });

              // Close loading modal first
              Navigator.of(context, rootNavigator: true).pop(context);

              // Show different dialog based on late status
              showDialog(
                context: context,
                builder: (context) => CustomAlert(
                  title: absenType == 'absenmasuk'
                      ? (_isLate() ? "Terlambat" : "Berhasil")
                      : "Berhasil",
                  message: absenType == 'absenmasuk'
                      ? _getCheckInMessage()
                      : "Absensi pulang berhasil. Selamat beristirahat!",
                  icon: Icons.check_circle_outline,
                  iconColor: Color.fromRGBO(1, 101, 65, 1),
                ),
              );

              // Trigger attendance update notification
              _attendanceService.notifyListeners();

              // Refresh data from API after successful check-in/out
              _loadAttendanceData();

              return "absen berhasil";
            } else {
              String message = jsonDecode(result)['message'];
              Navigator.of(context, rootNavigator: true).pop(context);
              showDialog(
                context: context,
                builder: (context) => CustomAlert(
                  title: "Warning",
                  message: message,
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.red,
                ),
              );
              return "absen gagal";
            }
          } on TimeoutException catch (e) {
            print('\n=== Attendance request timeout ===');
            print('Error: $e');
            Navigator.of(context, rootNavigator: true).pop(context);
            showDialog(
              context: context,
              builder: (context) => CustomAlert(
                title: "Warning",
                message: "Koneksi timeout, silahkan coba lagi!",
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
              ),
            );
            return "absen gagal";
          } catch (e) {
            print('\n=== Attendance request error ===');
            print('Error: $e');
            Navigator.of(context, rootNavigator: true).pop(context);
            showDialog(
              context: context,
              builder: (context) => CustomAlert(
                title: "Warning",
                message: "Terjadi kesalahan, silahkan coba lagi!",
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
              ),
            );
            return "absen gagal";
          }
        } else {
          Navigator.of(context, rootNavigator: true).pop(context);
          showDialog(
            context: context,
            builder: (context) => CustomAlert(
              title: "Warning",
              message: "Anda berada diluar radius kantor!",
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
            ),
          );
          return "absen gagal";
        }
      } else {
        String message = jsonDecode(
            checkSessionResult.body.toString().replaceAll('""', ""))['message'];
        Navigator.of(context, rootNavigator: true).pop(context);
        showDialog(
          context: context,
          builder: (context) => CustomAlert(
            title: "Warning",
            message: message,
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
          ),
        );
        return "absen gagal";
      }
    } on TimeoutException catch (e) {
      print('\n=== Check session timeout ===');
      print('Error: $e');
      Navigator.of(context, rootNavigator: true).pop(context);
      showDialog(
        context: context,
        builder: (context) => CustomAlert(
          title: "Warning",
          message: "Koneksi timeout, silahkan coba lagi!",
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
        ),
      );
      return "absen gagal";
    } catch (e) {
      print('\n=== Check session error ===');
      print('Error: $e');
      Navigator.of(context, rootNavigator: true).pop(context);
      showDialog(
        context: context,
        builder: (context) => CustomAlert(
          title: "Warning",
          message: "Terjadi kesalahan, silahkan coba lagi!",
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
        ),
      );
      return "absen gagal";
    }
  }

  bool _isLate() {
    // Define the standard start time
    final standardStartTime = DateTime(DateTime.now().year,
        DateTime.now().month, DateTime.now().day, 7, 45, 0 // 07:45 AM
        );

    final now = DateTime.now();
    final currentTime =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);

    return currentTime.isAfter(standardStartTime);
  }

  String _getCheckInMessage() {
    if (_isLate()) {
      return 'Anda terlambat melakukan absensi. Harap segera melakukan absensi dan memberikan keterangan keterlambatan.';
    } else {
      return 'Absensi berhasil dilakukan tepat waktu. Selamat bekerja!';
    }
  }

  void _updateAttendanceTime(String type, String time) {
    setState(() {
      if (type == 'absenmasuk') {
        _jamMasuk = time;
      } else {
        _jamPulang = time;
      }
    });
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
              message: 'Aplikasi tidak dapat digunakan karena perangkat tidak memenuhi persyaratan keamanan.',
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
            message: 'Tidak dapat memverifikasi keamanan perangkat. Pastikan perangkat Anda memenuhi persyaratan keamanan.',
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
          context, MaterialPageRoute(builder: (context) => Login()));
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
          CameraPosition(
            target: latLng,
            zoom: 17.0,
          ),
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
              'Could not get current location. Please check your location permissions.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _zoomToOffice() async {
    try {
      final GoogleMapController controller = await _controller.future;
      final latLng = LatLng(latKantor, longKantor);

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 17.0,
          ),
        ),
      );

      setState(() {
        currentLatLng = latLng;
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
                Theme.of(context).primaryColor.withOpacity(0.8),
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
                  circles: Set.from([
                    Circle(
                      circleId: CircleId("primary"),
                      center: LatLng(latKantor, longKantor),
                      radius: radius,
                      fillColor: Colors.blue.withOpacity(0.2),
                      strokeColor: Colors.blue.withOpacity(0.4),
                      strokeWidth: 2,
                    ),
                    if (useSecondLocation)
                      Circle(
                        circleId: CircleId("secondary"),
                        center: LatLng(latKantor2, longKantor2),
                        radius: radius2,
                        fillColor: Colors.blue.withOpacity(0.2),
                        strokeColor: Colors.blue.withOpacity(0.4),
                        strokeWidth: 2,
                      ),
                  ]),
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
                      final distance = Geolocator.distanceBetween(
                        userPosition.latitude,
                        userPosition.longitude,
                        latKantor,
                        longKantor,
                      );

                      final bool isOutsideRadius = distance > radius;

                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOutsideRadius
                              ? Colors.red[400]
                              : Colors.green[400],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                          color: Colors.black.withOpacity(0.1),
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
                  SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                              horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy')
                                    .format(DateTime.now()),
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
                                        borderRadius:
                                            BorderRadius.circular(10),
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
                                        borderRadius:
                                            BorderRadius.circular(10),
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
                          color: Colors.black.withOpacity(0.05),
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
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Main swipe button
                                Container(
                                  height: 56,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 60),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _selectedOption == 'Absen Masuk' 
                                                    ? 'Geser untuk Absen Masuk'
                                                    : 'Geser untuk Absen Pulang',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.waving_hand_rounded,
                                              color: Colors.yellow,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 60),
                                    ],
                                  ),
                                ),
                                // Sliding arrow button
                                if (_isSwipeEnabled)
                                  AnimatedPositioned(
                                    duration: Duration(
                                        milliseconds: _isSliding ? 0 : 200),
                                    curve: Curves.easeOutBack,
                                    left: 8 + _slideValue,
                                    top: 4,
                                    child: GestureDetector(
                                      onHorizontalDragStart: (details) {
                                        setState(() {
                                          _isSliding = true;
                                        });
                                      },
                                      onHorizontalDragUpdate: (details) {
                                        setState(() {
                                          _slideValue =
                                              (_slideValue + details.delta.dx)
                                                  .clamp(
                                                      0,
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width -
                                                          180);
                                        });
                                      },
                                      onHorizontalDragEnd: (details) {
                                        if (_slideValue >
                                            MediaQuery.of(context).size.width -
                                                220) {
                                          _checkRadius(
                                              _selectedOption == 'Absen Masuk'
                                                  ? 'absenmasuk'
                                                  : 'absenpulang');
                                          _fetchData(context);
                                        }
                                        setState(() {
                                          _isSliding = false;
                                          _slideValue = 0;
                                        });
                                      },
                                      child: TweenAnimationBuilder(
                                        duration: Duration(milliseconds: 150),
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: _slideValue /
                                              (MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  180),
                                        ),
                                        builder:
                                            (context, double value, child) {
                                          return Transform.scale(
                                            scale: 1 + (value * 0.1),
                                            child: Transform.rotate(
                                              angle: value * 0.5,
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                      spreadRadius: -2,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 28,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    left: 8,
                                    top: 4,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                            spreadRadius: -2,
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
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
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
      String title, Color color, VoidCallback onTap, bool isSelected) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(12),
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
