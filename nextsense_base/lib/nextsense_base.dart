import 'dart:async';

import 'package:flutter/services.dart';

typedef void Listener(dynamic msg);
typedef void CancelListening();

enum DeviceAttributesFields {
  macAddress,
  name
}

class NextsenseBase {
  static const MethodChannel _channel = const MethodChannel('nextsense_base');
  static const EventChannel _deviceScanStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_scan_channel');

  static int _nextScanningListenerId = 1;


  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future startService() async {
    return _channel.invokeMethod('connect_to_service');
  }

  static Future setFlutterActivityActive(bool active) async {
    return _channel.invokeMethod('set_flutter_activity_active', active);
  }

  static Future<int> get test async {
    final int connectedDevices = await _channel.invokeMethod('test');
    return connectedDevices;
  }

  static CancelListening startScanning(Listener listener) {
    var subscription = _deviceScanStream.receiveBroadcastStream(
        _nextScanningListenerId++
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }
}
