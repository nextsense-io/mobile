
import 'dart:async';

import 'package:flutter/services.dart';

class NextsenseBase {
  static const MethodChannel _channel =
      const MethodChannel('nextsense_base');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future startService() async {
    return _channel.invokeMethod('connectToService');
  }

  static Future setFlutterActivityActive(bool active) async {
    return _channel.invokeMethod('set_flutter_activity_active', active);
  }

  static Future<int> get test async {
    final int connectedDevices = await _channel.invokeMethod('test');
    return connectedDevices;
  }
}
