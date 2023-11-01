import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gson/gson.dart';

typedef void Listener(dynamic msg);
typedef void CancelListening();

// High-level type of the hardware device. This defines which API to use. A better way would be to
// expose the API but it would be quite a lot of effort to do.
enum DeviceType {
  h1,
  nitro,
  xenon,
  kauai
}

enum DeviceAttributesFields {
  macAddress,
  name,
  type,
  revision,
  serialNumber,
  firmwareVersionMajor,
  firmwareVersionMinor,
  firmwareVersionBuildNumber,
  earbudsType,
  earbudsRevision,
  earbudsSerialNumber,
  earbudsVersionMajor,
  earbudsVersionMinor,
  earbudsVersionBuildNumber,
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
  UNKNOWN(-1),
  OFF(0x00),
  ON_EXTERNAL_CURRENT(0x01),
  ON_1299_DC(0x02),
  ON_1299_AC(0x03);

  final int code;

  const ImpedanceMode(this.code);

  factory ImpedanceMode.create(int code) {
    return values.firstWhere((mode) => mode.code == code, orElse: () => UNKNOWN);
  }
}

// Changes in those commands should match constants in EmulatedDeviceManager.java
enum EmulatorCommand {
  NONE,
  CONNECT,
  DISCONNECT,
  INTERNAL_STATE_CHANGE
}

// String results from sleep staging will be one of those.
enum SleepStagingResult {
  n1,
  n2,
  n3,
  rem,
  wake
}

const int sleepResultsIndex = 0;
const int sleepConfidencesIndex = 1;

class NextsenseBase {
  static const MethodChannel _channel = const MethodChannel('nextsense_base');
  static const EventChannel _deviceScanStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_scan_channel');
  static const EventChannel _deviceStateStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_state_channel');
  static const EventChannel _deviceEventsStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_events_channel');
  static const EventChannel _deviceInternalStateStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/device_internal_state_channel');
  static const EventChannel _currentSessionDataReceivedStream = const EventChannel(
      'io.nextsense.flutter.base.nextsense_base/current_session_data_received_channel');
  static const String _connectToServiceCommand = 'connect_to_service';
  static const String _changeNotificationContentCommand = 'change_notification_content';
  static const String _setFlutterActivityActiveCommand =
      'set_flutter_activity_active';
  static const String _getConnectedDevicesCommand = 'get_connected_devices';
  static const String _connectDeviceCommand = 'connect_device';
  static const String _disconnectDeviceCommand = 'disconnect_device';
  static const String _getDeviceStateCommand = 'get_device_state';
  static const String _canStartNewSessionCommand = 'can_start_new_session';
  static const String _startStreamingCommand = 'start_streaming';
  static const String _stopStreamingCommand = 'stop_streaming';
  static const String _isDeviceStreamingCommand = 'is_device_streaming';
  static const String _startImpedanceCommand = 'start_impedance';
  static const String _stopImpedanceCommand = 'stop_impedance';
  static const String _setImpedanceConfigCommand = 'set_impedance_config';
  static const String _isBluetoothEnabledCommand = 'is_bluetooth_enabled';
  static const String _getChannelDataCommand = 'get_channel_data';
  static const String _getAccChannelDataCommand = 'get_acc_channel_data';
  static const String _getTimestampsDataCommand = 'get_timestamps_data';
  static const String _getDeviceInfoCommand = 'get_device_info';
  static const String _getDeviceSettingsCommand = 'get_device_settings';
  static const String _deleteLocalSessionCommand = 'delete_local_session';
  static const String _requestDeviceInternalStateUpdateCommand =
      'request_device_internal_state';
  static const String _setUploaderMinimumConnectivityCommand =
      'set_uploader_minimum_connectivity';
  static const String _getFreeDiskSpaceCommand = 'get_free_disk_space';
  static const String _getTimezoneIdCommand = 'get_timezone_id';
  static const String _getNativeLogsCommand = 'get_native_logs';
  static const String _runSleepStagingCommand = 'run_sleep_staging';
  static const String _emulatorCommand = 'emulator_command';
  static const String _macAddressArg = 'mac_address';
  static const String _uploadToCloudArg = 'upload_to_cloud';
  static const String _userBigTableKeyArg = 'user_bigtable_key';
  static const String _dataSessionIdArg = 'data_session_id';
  static const String _earbudsConfigArg = 'earbuds_config';
  static const String _localSessionIdArg = 'local_session_id';
  static const String _channelNumberArg = 'channel_number';
  static const String _durationMillisArg = 'duration_millis';
  static const String _impedanceModeArg = 'impedance_mode';
  static const String _frequencyDividerArg = 'frequency_divider';
  static const String _minConnectionTypeArg = 'min_connection_type';
  static const String _fromDatabaseArg = 'from_database';
  static const String _notificationTitleArg = 'notification_title';
  static const String _notificationTextArg = 'notification_text';
  static const String _connectToDeviceErrorNotFound = 'not_found';
  static const String _connectToDeviceErrorConnection = 'connection_error';
  static const String _connectToDeviceErrorInterrupted =
      'connection_interrupted';

  static int _nextScanningListenerId = 1;
  static int _nextDeviceStateListenerId = 1;
  static int _nextDeviceEventsListenerId = 1;
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

  static Future changeNotificationContent(String title, String text) async {
    await _channel.invokeMethod(_changeNotificationContentCommand,
        {_notificationTitleArg: title, _notificationTextArg: text});
  }

  static Future connectDevice(String macAddress) async {
    await _channel.invokeMethod(_connectDeviceCommand,
        {_macAddressArg: macAddress});
  }

  static Future disconnectDevice(String macAddress) async {
    await _channel.invokeMethod(_disconnectDeviceCommand,
        {_macAddressArg: macAddress});
  }

  static Future<List<double>> getChannelData({
      required String macAddress, required String channelName, required Duration duration,
          int? localSessionId, bool fromDatabase = false}) async {
    final List<Object?> channelData =
        await _channel.invokeMethod(_getChannelDataCommand,
        {_macAddressArg: macAddress, _localSessionIdArg: localSessionId,
          _channelNumberArg: channelName,
          _durationMillisArg: duration.inMilliseconds,
          _fromDatabaseArg: fromDatabase});
    return channelData.cast<double>();
  }

  static Future<List<int>> getAccChannelData({
    required String macAddress, required String channelName, required Duration duration,
    int? localSessionId, bool fromDatabase = false}) async {
    final List<Object?> channelData = await _channel.invokeMethod(_getAccChannelDataCommand,
        {_macAddressArg: macAddress, _localSessionIdArg: localSessionId,
          _channelNumberArg: channelName,
          _durationMillisArg: duration.inMilliseconds,
          _fromDatabaseArg: fromDatabase});
    return channelData.cast<int>();
  }

  static Future<List<int>> getTimestampsData({
      required String macAddress, required Duration duration}) async {
    final List<Object?> channelData = await _channel.invokeMethod(_getTimestampsDataCommand,
        {_macAddressArg: macAddress, _durationMillisArg: duration.inMilliseconds});
    return channelData.cast<int>();
  }

  /**
   * Returns a map of of two lists: sleep results and sleep confidences.
   * Each map can be obtained with the index from `sleepResultsIndex` and `sleepConfidencesIndex`.
   * Sleep results will conform to the `SleepStagingResult` enum.
   * Sleep confidences will be a list of doubles between 0 and 1.
   */
  static Future<Map<String, dynamic>> runSleepStaging({
    required String macAddress, required String channelName, required Duration duration,
    required int localSessionId, bool fromDatabase = true}) async {
    final Map<String, dynamic> channelData =
        gson.decode(await _channel.invokeMethod(_runSleepStagingCommand,
        {_macAddressArg: macAddress, _localSessionIdArg: localSessionId,
          _channelNumberArg: channelName,
          _durationMillisArg: duration.inMilliseconds,
          _fromDatabaseArg: fromDatabase}));
    return channelData;
  }

  static Future deleteLocalSession(int localSessionId) async {
    await  _channel.invokeMethod(_deleteLocalSessionCommand,
        {_localSessionIdArg: localSessionId});
  }

  static CancelListening startScanning(Listener listener) {
    var subscription = _deviceScanStream.receiveBroadcastStream(_nextScanningListenerId++)
        .listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static Future<String> getDeviceState(String macAddress) async {
    return await _channel.invokeMethod(_getDeviceStateCommand, {_macAddressArg: macAddress});
  }

  static CancelListening listenToDeviceState(Listener listener, String deviceMacAddress) {
    var subscription = _deviceStateStream.receiveBroadcastStream(
        [_nextDeviceStateListenerId++, deviceMacAddress]
    ).listen(listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static CancelListening listenToDeviceEvents(Listener listener, String deviceMacAddress) {
    var subscription = _deviceEventsStream.receiveBroadcastStream(
        [_nextDeviceEventsListenerId++, deviceMacAddress]
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

  static CancelListening listenToCurrentSessionDataReceived(Listener listener) {
    var subscription = _currentSessionDataReceivedStream.receiveBroadcastStream().listen(
        listener, cancelOnError: true);
    return () {
      subscription.cancel();
    };
  }

  static Future<bool> canStartNewSession() async {
    return await _channel.invokeMethod(_canStartNewSessionCommand);
  }

  static Future<int> startStreaming(String macAddress, bool uploadToCloud, String? userBigTableKey,
      String? dataSessionId, String? earbudsConfig) async {
    return await _channel.invokeMethod(_startStreamingCommand,
        {_macAddressArg: macAddress, _uploadToCloudArg: uploadToCloud,
          _userBigTableKeyArg: userBigTableKey, _dataSessionIdArg: dataSessionId,
          _earbudsConfigArg: earbudsConfig});
  }

  static Future stopStreaming(String macAddress) async {
    await _channel.invokeMethod(_stopStreamingCommand, {_macAddressArg: macAddress});
  }

  static Future<bool> isDeviceStreaming(String macAddress) async {
    return await _channel.invokeMethod(_isDeviceStreamingCommand, {_macAddressArg: macAddress});
  }

  static Future<int> startImpedance(String macAddress, ImpedanceMode impedanceMode,
      int? channelNumber, int? frequencyDivider) async {
    return await _channel.invokeMethod(_startImpedanceCommand,
        {_macAddressArg: macAddress,
          _impedanceModeArg: describeEnum(impedanceMode),
          _channelNumberArg: channelNumber,
          _frequencyDividerArg: frequencyDivider});
  }

  static Future<bool> stopImpedance(String macAddress) async {
    return await _channel.invokeMethod(_stopImpedanceCommand,
        {_macAddressArg: macAddress});
  }

  static Future setImpedanceConfig(String macAddress, ImpedanceMode impedanceMode,
      int? channelNumber, int? frequencyDivider) async {
    return await _channel.invokeMethod(_setImpedanceConfigCommand,
        {_macAddressArg: macAddress,
          _impedanceModeArg: describeEnum(impedanceMode),
          _channelNumberArg: channelNumber,
          _frequencyDividerArg: frequencyDivider});
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

  static Future<Map<String, dynamic>> getDeviceInfo(String macAddress) async {
    String deviceInfoJson = (await _channel.invokeMethod(_getDeviceInfoCommand,
        {_macAddressArg: macAddress})) as String;
    return gson.decode(deviceInfoJson);
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

  static Future<double> getFreeDiskSpaceMb() async {
    return await _channel.invokeMethod(_getFreeDiskSpaceCommand);
  }

  static Future<String> getTimezoneId() async {
    return await _channel.invokeMethod(_getTimezoneIdCommand);
  }

  static Future<String> getNativeLogs() async {
    return await _channel.invokeMethod(_getNativeLogsCommand);
  }

  static Future<bool> sendEmulatorCommand(EmulatorCommand command,
      {Map<String, dynamic> params = const {}}) async {
    return await _channel.invokeMethod(_emulatorCommand,
        {'command': command.name, 'params' : params });
  }
}
