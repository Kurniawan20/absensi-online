import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './home_page.dart';
import './page_presence.dart';
import './page_login.dart';
import './settings_page.dart';
import 'dart:math' as math;
import '../utils/storage_config.dart';

class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Create a pattern of circles
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 20 + 5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Add some diagonal lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke;

    for (int i = -5; i < 20; i++) {
      final y = i * 50.0;
      canvas.drawLine(
        Offset(-50, y),
        Offset(size.width + 50, y + size.width),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create overlapping rectangles
    var path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();

    var path2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();

    // Draw the paths with different opacities
    canvas.drawPath(path1, paint..color = Colors.black.withOpacity(0.05));
    canvas.drawPath(path2, paint..color = Colors.black.withOpacity(0.07));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? npp;
  String? name;
  String? officeCode;
  String? officeName;
  String? department;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      npp = prefs.getString('npp');
      name = prefs.getString('nama');
      officeCode = prefs.getString('kode_kantor');
      officeName = prefs.getString('nama_kantor');
      department = prefs.getString('ket_bidang');
      imageUrl = prefs.getString('image_url');
    });
  }

  Future<void> signOut() async {
    print('Starting sign out process');
    final storage = StorageConfig.secureStorage;

    // Save biometric state before clearing
    final isBiometricEnabled = await storage.read(key: 'biometric_enabled');
    final savedCredentials = await storage.read(key: 'saved_credentials');
    print(
        'Current biometric state - enabled: $isBiometricEnabled, has credentials: ${savedCredentials != null}');

    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Clear secure storage but preserve biometric settings if enabled
    await storage.deleteAll();
    if (isBiometricEnabled?.toLowerCase() == 'true' &&
        savedCredentials != null) {
      print('Preserving biometric settings and credentials');
      await storage.write(key: 'biometric_enabled', value: 'true');
      await storage.write(key: 'saved_credentials', value: savedCredentials);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            color: Colors.white,
            onPressed: () {
              // Add settings functionality here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300, // Increased height to accommodate content
              decoration: BoxDecoration(
                color: const Color.fromRGBO(1, 101, 65, 1),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: GeometricPatternPainter(),
                    size: Size(
                        double.infinity, 300), // Match the container height
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        20,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 212, 212, 212),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/avatar_3d.jpg',
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                npp ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      FluentIcons.person_24_regular,
                      color: Colors.grey,
                      size: 24,
                    ),
                    title: const Text(
                      'Nama',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      name ?? '-',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      FluentIcons.building_24_regular,
                      color: Colors.grey,
                      size: 24,
                    ),
                    title: const Text(
                      'Kode Kantor',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      officeCode ?? '-',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      FluentIcons.building_bank_24_regular,
                      color: Colors.grey,
                      size: 24,
                    ),
                    title: const Text(
                      'Nama Kantor',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      officeName ?? '-',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      FluentIcons.settings_24_regular,
                      color: Colors.grey,
                      size: 24,
                    ),
                    title: const Text(
                      'Pengaturan',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: signOut,
                icon: const Icon(
                  FluentIcons.sign_out_24_regular,
                  color: Color(0xFFFF4343),
                  size: 20,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFFF4343),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
