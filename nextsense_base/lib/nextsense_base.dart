import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gson/gson.dart';

typedef void Listener(dynamic msg);
typedef void CancelListening();

enum DeviceAttributesFields {
  macAddress,
  name
}

enum DeviceSettingsFields {
  eegSamplingRate,
  eegStreamingRate,
  imuSamplingRate,
  imuStreamingRate,
  enabledChannels,
  impedanceMode,
  impedanceDivider
}

// This should stay in sync with
// io.nextsense.android.base.DeviceSettings.ImpedanceMode.
enum ImpedanceMode {
  OFF,
  ON_EXTERNAL_CURRENT,
  ON_1299_DC,
  ON_1299_AC
}

// Changes in those commands should match constants in EmulatedDeviceManager.java
enum EmulatorCommand {
  NONE,
  CONNECT,
  DISCONNECT,
  INTERNAL_STATE_CHANGE
}

class NextsenseBase {
  static const MethodChannel _channel = const MethodChannel('nextsense_base');
  static const EventChannel _deviceScanStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_scan_channel');
  static const EventChannel _deviceStateStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_state_channel');
  static const EventChannel _deviceInternalStateStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_internal_state_channel');
  static const String _connectToServiceCommand = 'connect_to_service';
  static const String _setFlutterActivityActiveCommand =
      'set_flutter_activity_active';
  static const String _getConnectedDevicesCommand = 'get_connected_devices';
  static const String _connectDeviceCommand = 'connect_device';
  static const String _disconnectDeviceCommand = 'disconnect_device';
  static const String _startStreamingCommand = 'start_streaming';
  static const String _stopStreamingCommand = 'stop_streaming';
  static const String _startImpedanceCommand = 'start_impedance';
  static const String _stopImpedanceCommand = 'stop_impedance';
  static const String _isBluetoothEnabledCommand = 'is_bluetooth_enabled';
  static const String _getChannelDataCommand = 'get_channel_data';
  static const String _getDeviceSettingsCommand = 'get_device_settings';
  static const String _deleteLocalSessionCommand = 'delete_local_session';
  static const String _requestDeviceInternalStateUpdateCommand =
      'request_device_internal_state';
  static const String _setUploaderMinimumConnectivityCommand =
      'set_uploader_minimum_connectivity';
  static const String _emulatorCommand = 'emulator_command';
  static const String _macAddressArg = 'mac_address';
  static const String _uploadToCloudArg = 'upload_to_cloud';
  static const String _userBigTableKeyArg = 'user_bigtable_key';
  static const String _dataSessionIdArg = 'data_session_id';
  static const String _localSessionIdArg = 'local_session_id';
  static const String _channelNumberArg = 'channel_number';
  static const String _durationMillisArg = 'duration_millis';
  static const String _impedanceModeArg = 'impedance_mode';
  static const String _frequencyDividerArg = 'frequency_divider';
  static const String _minConnectionTypeArg = 'min_connection_type';
  static const String _connectToDeviceErrorNotFound = 'not_found';
  static const String _connectToDeviceErrorConnection = 'connection_error';
  static const String _connectToDeviceErrorInterrupted =
      'connection_interrupted';

  static int _nextScanningListenerId = 1;
  static int _nextDeviceStateListenerId = 1;
  static int _nextDeviceInternalStateListenerId = 1;

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
        {_macAddressArg: macAddress});
  }

  static Future disconnectDevice(String macAddress) async {
    await _channel.invokeMethod(_disconnectDeviceCommand,
        {_macAddressArg: macAddress});
  }

  static Future<List<double>> getChannelData(
      String macAddress, int localSessionId, int channelNumber,
      Duration duration) async {
    final List<Object?> channelData =
        await _channel.invokeMethod(_getChannelDataCommand,
        {_macAddressArg: macAddress, _localSessionIdArg: localSessionId,
          _channelNumberArg: channelNumber,
          _durationMillisArg: duration.inMilliseconds});
    return channelData.cast<double>();
  }

  static Future deleteLocalSession(int localSessionId) async {
    await  _channel.invokeMethod(_deleteLocalSessionCommand,
        {_localSessionIdArg: localSessionId});
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
        [_nextDeviceStateListenerId++, deviceMacAddress]
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static CancelListening listenToDeviceInternalState(Listener listener) {
    var subscription = _deviceInternalStateStream.receiveBroadcastStream(
        [_nextDeviceInternalStateListenerId++]
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static Future<int> startStreaming(String macAddress, bool uploadToCloud,
      String userBigTableKey, String dataSessionId) async {
    return await _channel.invokeMethod(_startStreamingCommand,
        {_macAddressArg: macAddress, _uploadToCloudArg: uploadToCloud,
          _userBigTableKeyArg: userBigTableKey, _dataSessionIdArg: dataSessionId});
  }

  static Future stopStreaming(String macAddress) async {
    await _channel.invokeMethod(_stopStreamingCommand,
        {_macAddressArg: macAddress});
  }

  static Future<int> startImpedance(String macAddress,
      ImpedanceMode impedanceMode, int? channelNumber,
      int? frequencyDivider) async {
    return await _channel.invokeMethod(_startImpedanceCommand,
        {_macAddressArg: macAddress,
          _impedanceModeArg: describeEnum(impedanceMode),
          _channelNumberArg: channelNumber,
          _frequencyDividerArg: frequencyDivider});
  }

  static Future stopImpedance(String macAddress) async {
    await _channel.invokeMethod(_stopImpedanceCommand,
        {_macAddressArg: macAddress});
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

  static Future<Map<String, dynamic>> getDeviceSettings(String macAddress) async {
    String deviceSettingsJson = (await _channel.invokeMethod(_getDeviceSettingsCommand,
        {_macAddressArg: macAddress})) as String;
    return gson.decode(deviceSettingsJson);
  }

  static Future requestDeviceStateUpdate(String macAddress) async {
    await _channel.invokeMethod(_requestDeviceInternalStateUpdateCommand,
        {_macAddressArg: macAddress});
  }

  static Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod(_isBluetoothEnabledCommand);
  }

  static Future setUploaderMinimumConnectivity(String connectionType) async {
    return await _channel.invokeMethod(_setUploaderMinimumConnectivityCommand,
        {_minConnectionTypeArg: connectionType});
}

  static Future<bool> sendEmulatorCommand(EmulatorCommand command,
      {Map<String, dynamic> params = const {}}) async {
    return await _channel.invokeMethod(_emulatorCommand,
      {'command': command.name, 'params' : params });
  }
}
