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
  static const String _connectToServiceCommand = 'connect_to_service';
  static const String _connectToDeviceCommand = 'connect_to_device';
  static const String _connectToDeviceMacAddress = "mac_address";
  static const String _connectToDeviceErrorNotFound = "not_found";
  static const String _connectToDeviceErrorConnection = "connection_error";
  static const String _connectToDeviceErrorInterrupted =
      "connection_interrupted";
  static int _nextScanningListenerId = 1;


  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future setFlutterActivityActive(bool active) async {
    return _channel.invokeMethod('set_flutter_activity_active', active);
  }

  static Future startService() async {
    return _channel.invokeMethod(_connectToServiceCommand);
  }

  static Future connectDevice(String macAddress) async {
    await _channel.invokeMethod(_connectToDeviceCommand,
        {_connectToDeviceMacAddress: macAddress});
  }

  static CancelListening startScanning(Listener listener) {
    var subscription = _deviceScanStream.receiveBroadcastStream(
        _nextScanningListenerId++
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static Future<int> get test async {
    final int connectedDevices = await _channel.invokeMethod('test');
    return connectedDevices;
  }
}
