import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';

class EmulatorWarning extends StatelessWidget {
  var message;
  EmulatorWarning({Key? key, required this.message}) : super(key: key);

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
