import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'Bahasa Indonesia';
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

    print('Loaded biometric enabled: $biometricEnabled');

    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _biometricEnabled = biometricEnabled;
        _selectedLanguage = prefs.getString('language') ?? 'Bahasa Indonesia';
      });
    }
  }

  Future<void> _saveSettings() async {
    print('Saving settings...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);

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
                  'Silakan login terlebih dahulu untuk mengaktifkan login sidik jari'),
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
              ? 'Login sidik jari diaktifkan'
              : 'Login sidik jari dinonaktifkan'),
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
                activeColor: const Color.fromRGBO(1, 101, 65, 1),
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
                activeColor: const Color.fromRGBO(1, 101, 65, 1),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                FluentIcons.translate_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Bahasa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show language selection dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pilih Bahasa'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Bahasa Indonesia'),
                            leading: Radio<String>(
                              value: 'Bahasa Indonesia',
                              groupValue: _selectedLanguage,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                                _saveSettings();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('English'),
                            leading: Radio<String>(
                              value: 'English',
                              groupValue: _selectedLanguage,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                                _saveSettings();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
              subtitle: const Text('1.0.0'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                FluentIcons.document_24_regular,
                color: Color.fromRGBO(1, 101, 65, 1),
              ),
              title: const Text(
                'Kebijakan Privasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to privacy policy
              },
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
                // Navigate to terms and conditions
              },
            ),
          ],
        ),
      ),
    );
  }
}
