import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class EmulatorWarning extends StatelessWidget {
  final String message;
  const EmulatorWarning({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
}
