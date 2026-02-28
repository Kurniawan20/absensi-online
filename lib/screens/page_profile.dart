import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './page_login.dart';
import './settings_page.dart';
import '../utils/storage_config.dart';
import '../services/avatar_service.dart';
import '../painters/islamic_arch_painter.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? npp;
  String? name;
  String? officeCode;
  String? officeName;
  String? department;
  String? imageUrl;
  String _selectedAvatar = AvatarService.defaultAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = await AvatarService.getSelectedAvatar();
    setState(() {
      npp = prefs.getString('npp');
      name = prefs.getString('nama');
      officeCode = prefs.getString('kode_kantor');
      officeName = prefs.getString('nama_kantor');
      department = prefs.getString('ket_bidang');
      imageUrl = prefs.getString('image_url');
      _selectedAvatar = avatar;
    });
  }

  void _showAvatarSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            const SizedBox(height: 20),
            const Text(
              'Pilih Avatar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih avatar yang sesuai dengan Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            FutureBuilder<List<Map<String, String>>>(
              future: AvatarService.getAvatarsByGender(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final avatars = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: avatars.map((avatar) {
                    final isSelected = avatar['path'] == _selectedAvatar;
                    return GestureDetector(
                      onTap: () async {
                        final avatarService = AvatarService();
                        await avatarService.setSelectedAvatar(avatar['path']!);
                        setState(() {
                          _selectedAvatar = avatar['path']!;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color.fromRGBO(1, 101, 65, 1)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  avatar['path']!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              avatar['label']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color.fromRGBO(1, 101, 65, 1)
                                    : Colors.grey[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(1, 101, 65, 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Terpilih',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color.fromRGBO(1, 101, 65, 1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: IslamicArchPainter(),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top +
                                kToolbarHeight), // Offset for AppBar
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 212, 212, 212),
                                  width: 3,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: _showAvatarSelector,
                                child: Stack(
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        _selectedAvatar,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color.fromRGBO(1, 101, 65, 1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name ?? 'Loading...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              npp ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
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
