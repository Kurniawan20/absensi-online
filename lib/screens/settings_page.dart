import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/secure_storage_service.dart';
import 'terms_and_conditions_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;

  String _appVersion = '1.0.0'; // Default fallback
  final _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    print('Loading settings...');
    final prefs = await SharedPreferences.getInstance();

    final biometricEnabled = await _secureStorage.isBiometricEnabled();

    // Get app version
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      print('Error getting app version: $e');
    }

    print('Loaded biometric enabled: $biometricEnabled');

    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _biometricEnabled = biometricEnabled;
      });
    }
  }

  Future<void> _saveSettings() async {
    print('Saving settings...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    print('Setting biometric enabled to: $_biometricEnabled');
    await _secureStorage.setBiometricEnabled(_biometricEnabled);

    // If biometric is disabled, clear stored credentials
    if (!_biometricEnabled) {
      await _secureStorage.deleteCredentials();
    }
  }

  Future<void> _onBiometricToggle(bool value) async {
    print('Toggling biometric to: $value');

    if (value) {
      // Show confirmation dialog before enabling
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(1, 101, 65, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FluentIcons.fingerprint_24_regular,
                    color: Color.fromRGBO(1, 101, 65, 1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aktifkan Login Biometrik',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dengan mengaktifkan fitur ini:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDialogBullet(
                    'Anda dapat login menggunakan sidik jari atau pengenalan wajah.'),
                _buildDialogBullet(
                    'Kredensial Anda akan disimpan secara aman di perangkat ini.'),
                _buildDialogBullet(
                    'Anda dapat menonaktifkan fitur ini kapan saja.'),
                const SizedBox(height: 16),
                Text(
                  'Apakah Anda yakin ingin mengaktifkan login biometrik?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Aktifkan',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return; // User cancelled
      }

      // If enabling biometric, we need to save current credentials
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      final password = prefs.getString('password');

      if (email != null && password != null) {
        await _secureStorage.saveCredentials(email, password);
        setState(() {
          _biometricEnabled = value;
        });
        await _saveSettings();
      } else {
        // Show error if no credentials available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Silakan login terlebih dahulu untuk mengaktifkan login biometrik'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              margin: EdgeInsets.all(10),
            ),
          );
        }
        return;
      }
    } else {
      // If disabling, just update state and clear credentials
      setState(() {
        _biometricEnabled = value;
      });
      await _saveSettings();
    }

    // Show confirmation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Login biometrik diaktifkan'
              : 'Login biometrik dinonaktifkan'),
          backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Widget _buildDialogBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(1, 101, 65, 1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
        elevation: 0,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                FluentIcons.alert_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
                activeThumbColor: const Color.fromRGBO(1, 101, 65, 1),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                FluentIcons.fingerprint_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Login dengan Biometric',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _onBiometricToggle,
                activeThumbColor: const Color.fromRGBO(1, 101, 65, 1),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                FluentIcons.info_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Versi Aplikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(_appVersion),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                FluentIcons.book_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Syarat dan Ketentuan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
