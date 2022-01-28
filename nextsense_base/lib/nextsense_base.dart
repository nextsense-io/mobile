import 'dart:core';

import 'package:flutter/services.dart';
import 'package:gson/gson.dart';

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
  static const EventChannel _deviceStateStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_state_channel');
  static const String _connectToServiceCommand = 'connect_to_service';
  static const String _setFlutterActivityActiveCommand =
      'set_flutter_activity_active';
  static const String _getConnectedDevicesCommand = 'get_connected_devices';
  static const String _connectDeviceCommand = 'connect_device';
  static const String _disconnectDeviceCommand = 'disconnect_device';
  static const String _startStreamingCommand = 'start_streaming';
  static const String _stopStreamingCommand = 'stop_streaming';
  static const String _isBluetoothEnabledCommand = 'is_bluetooth_enabled';
  static const String _macAddress = 'mac_address';
  static const String _userBigTableKey = 'user_bigtable_key';
  static const String _dataSessionId = 'data_session_id';
  static const String _connectToDeviceErrorNotFound = 'not_found';
  static const String _connectToDeviceErrorConnection = 'connection_error';
  static const String _connectToDeviceErrorInterrupted =
      'connection_interrupted';
  static int _nextScanningListenerId = 1;
  static int _nextStateListenerId = 1;

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future setFlutterActivityActive(bool active) async {
    return _channel.invokeMethod(_setFlutterActivityActiveCommand, active);
  }

  static Future startService() async {
    return _channel.invokeMethod(_connectToServiceCommand);
  }

  static Future connectDevice(String macAddress) async {
    await _channel.invokeMethod(_connectDeviceCommand,
        {_macAddress: macAddress});
  }

  static Future disconnectDevice(String macAddress) async {
    await _channel.invokeMethod(_disconnectDeviceCommand,
        {_macAddress: macAddress});
  }

  static CancelListening startScanning(Listener listener) {
    var subscription = _deviceScanStream.receiveBroadcastStream(
        _nextScanningListenerId++
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static CancelListening listenToDeviceState(Listener listener,
      String deviceMacAddress) {
    var subscription = _deviceStateStream.receiveBroadcastStream(
        [_nextStateListenerId++, deviceMacAddress]
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static Future startStreaming(String macAddress, String userBigTableKey,
      String dataSessionId) async {
    await _channel.invokeMethod(_startStreamingCommand,
        {_macAddress: macAddress, _userBigTableKey: userBigTableKey,
         _dataSessionId: dataSessionId});
  }

  static Future stopStreaming(String macAddress) async {
    await _channel.invokeMethod(_stopStreamingCommand,
        {_macAddress: macAddress});
  }

  static Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    List<Object?> connectedDevicesJson =
        await _channel.invokeMethod(_getConnectedDevicesCommand);
    List<Map<String, dynamic>> connectedDevices = [];
    for (Object? connectedDeviceJson in connectedDevicesJson) {
      connectedDevices.add(gson.decode(connectedDeviceJson as String));
    }
    return connectedDevices;
  }

  static Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod(_isBluetoothEnabledCommand);
  }
}
