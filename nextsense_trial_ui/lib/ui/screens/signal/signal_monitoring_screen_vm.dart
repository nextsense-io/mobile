import 'dart:async';

import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_settings.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

enum DataType {
  eeg,
  acceleration,
  unknown;

  factory DataType.create(String? value, {DataType defaultValue = DataType.eeg}) {
    if (value == null) {
      return defaultValue;
    }
    return values.firstWhere((element) => element.name == value, orElse: () => unknown);
  }
}

// What kind of signal processing to do when visualizing.
enum SignalProcessing {
  raw,
  filtered,
  unknown;

  factory SignalProcessing.create(String? value,
      {SignalProcessing defaultValue = SignalProcessing.filtered}) {
    if (value == null) {
      return defaultValue;
    }
    return values.firstWhere((element) => element.name == value, orElse: () => unknown);
  }
}

/* Acceleration data class. */
class AccelerationData implements Comparable<AccelerationData> {
  final int x;
  final int y;
  final int z;
  final DateTime timestamp;

  AccelerationData({required this.x, required this.y, required this.z, required this.timestamp});

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  int getZ() {
    return z;
  }

  int getTimestampMs() {
    return timestamp.millisecondsSinceEpoch;
  }

  List<int> asList() {
    return [x, y, z];
  }

  List<int> asListWithTimestamp() {
    return [x, y, z, timestamp.millisecondsSinceEpoch];
  }

  @override
  int compareTo(AccelerationData other) {
    return timestamp.difference(other.timestamp).inMilliseconds;
  }
}

class SignalMonitoringScreenViewModel extends DeviceStateViewModel {

  static const Duration _eegTimeWindowDefault = Duration(seconds: 5);
  static const Duration _eegTimeWindowMin = Duration(seconds: 1);
  static const Duration _eegTimeWindowMax = Duration(seconds: 30);
  static const Duration _accTimeWindowDefault = Duration(seconds: 5);
  static const Duration _accTimeWindowMin = Duration(seconds: 1);
  static const Duration _accTimeWindowMax = Duration(seconds: 30);
  static const Duration _refreshInterval = Duration(milliseconds: 100);
  static const double _defaultMaxAmplitudeMicroVolts = 50;

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final _preferences = getIt<Preferences>();

  Device? device;
  DeviceSettings? _deviceSettings;
  String? _selectedChannel;
  DataType _dataType = DataType.eeg;
  SignalProcessing _eegSignalProcessing = SignalProcessing.filtered;
  Duration timeWindowMin = _eegTimeWindowMin;
  Duration timeWindowMax = _eegTimeWindowMax;
  Duration _graphTimeWindow = _eegTimeWindowDefault;
  List<String> eegChannelList = [];
  int samplesToShow = 1250;
  double streamingFrequencyHz = 250;
  double _eegAmplitudeMicroVolts = _defaultMaxAmplitudeMicroVolts;
  // List<AccelerationData>? accData = [];
  Timer? _screenRefreshTimer;

  SignalMonitoringScreenViewModel() {
    setBusy(true);
  }

  @override
  void init() async {
    super.init();
    device = _deviceManager.getConnectedDevice();
    eegAmplitudeMicroVolts = _preferences.getDouble(PreferenceKey.displayMaxAmplitude) ??
        _defaultMaxAmplitudeMicroVolts;
    if (device != null) {
      _deviceSettings = DeviceSettings(await NextsenseBase.getDeviceSettings(device!.macAddress));
      dataType = DataType.create(_preferences.getString(PreferenceKey.displayDataType));
      eegChannelList = _deviceSettings!.enabledChannels;
      selectedChannel = _preferences.getString(PreferenceKey.displaySelectedChannel) ??
          eegChannelList[0];
      await NextsenseBase.startStreaming(
          device!.macAddress, /*uploadToCloud=*/false, /*continuousImpedance=*/false,
          /*userBigTableKey=*/"", /*dataSessionId=*/"", /*earbudsConfig=*/null);
    }
    _updateTimeSlider();
    _screenRefreshTimer = new Timer.periodic(_refreshInterval, _updateScreen);
    setBusy(false);
    setInitialised(true);
    notifyListeners();
  }

  @override
  void dispose() async {
    _screenRefreshTimer?.cancel();
    if (device != null) {
      await NextsenseBase.stopStreaming(device!.macAddress);
    }
    super.dispose();
  }

  // Future _getAccData() async {
  //   List<int> timestamps = await NextsenseBase.getTimestampsData(
  //       macAddress: device!.macAddress, duration: graphTimeWindow);
  //   List<int> accXData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
  //       channelName: 'x', duration: graphTimeWindow, fromDatabase: false);
  //   List<int> accYData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
  //       channelName: 'y', duration: graphTimeWindow, fromDatabase: false);
  //   List<int> accZData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
  //       channelName: 'z', duration: graphTimeWindow, fromDatabase: false);
  //   List<AccelerationData> accelerations = [];
  //   for (int i = 0; i < timestamps.length; ++i) {
  //     accelerations.add(AccelerationData(x: accXData[i].toInt(), y: accYData[i].toInt(),
  //         z: accZData[i].toInt(), timestamp:
  //         DateTime.fromMillisecondsSinceEpoch(timestamps[i].toInt())));
  //   }
  //   accData = accelerations;
  // }

  void _updateTimeSlider() {
    if (dataType == DataType.eeg) {
      graphTimeWindow = _preferences.getInt(PreferenceKey.displayEegTimeWindowSeconds) != null ?
          Duration(seconds: _preferences.getInt(PreferenceKey.displayEegTimeWindowSeconds)!) :
          _eegTimeWindowDefault;
      timeWindowMin = _eegTimeWindowMin;
      timeWindowMax = _eegTimeWindowMax;
    } else if (dataType == DataType.acceleration) {
      graphTimeWindow = _preferences.getInt(PreferenceKey.displayAccTimeWindowSeconds) != null ?
          Duration(seconds: _preferences.getInt(PreferenceKey.displayAccTimeWindowSeconds)!) :
          _accTimeWindowDefault;
      timeWindowMin = _accTimeWindowMin;
      timeWindowMax = _accTimeWindowMax;
    }
    notifyListeners();
  }

  void _updateScreen(Timer timer) {
    // if (dataType == DataType.eeg) {
    //
    // } else {
    //   _getAccData();
    // }
    notifyListeners();
  }

  @override
  void onDeviceDisconnected() {
    // TODO: implement onDeviceDisconnected
  }

  @override
  void onDeviceReconnected() {
    // TODO: implement onDeviceReconnected
  }

  DataType get dataType => _dataType;

  set dataType(DataType? value) {
    print("data type: ${value}");
    if (value == null) {
      return;
    }
    _dataType = value;
    if (dataType == DataType.eeg) {
      graphTimeWindow = _preferences.getInt(PreferenceKey.displayEegTimeWindowSeconds) != null ?
      Duration(seconds: _preferences.getInt(PreferenceKey.displayEegTimeWindowSeconds)!) :
      _eegTimeWindowDefault;
      streamingFrequencyHz = _deviceSettings!.eegStreamingRate!;
    } else if (dataType == DataType.acceleration) {
      graphTimeWindow = _preferences.getInt(PreferenceKey.displayAccTimeWindowSeconds) != null ?
      Duration(seconds: _preferences.getInt(PreferenceKey.displayAccTimeWindowSeconds)!) :
      _accTimeWindowDefault;
      streamingFrequencyHz = _deviceSettings!.imuStreamingRate!;
    }
    samplesToShow = (graphTimeWindow.inSeconds * streamingFrequencyHz).toInt();
    notifyListeners();
  }

  String get selectedChannel => _selectedChannel ?? "None";

  set selectedChannel(String channelName) {
    _selectedChannel = channelName;
    _preferences.setString(PreferenceKey.displaySelectedChannel, channelName);
    notifyListeners();
  }

  SignalProcessing get eegSignalProcessing => _eegSignalProcessing;

  set eegSignalProcessing(SignalProcessing value) {
    _eegSignalProcessing = value;
    notifyListeners();
  }

  Duration get graphTimeWindow => _graphTimeWindow;

  set graphTimeWindow(Duration value) {
    _graphTimeWindow = value;
    samplesToShow = (graphTimeWindow.inSeconds * streamingFrequencyHz).toInt();
    if (dataType == DataType.eeg) {
      _preferences.setInt(PreferenceKey.displayEegTimeWindowSeconds, value.inSeconds);
    } else if (dataType == DataType.acceleration) {
      _preferences.setInt(PreferenceKey.displayAccTimeWindowSeconds, value.inSeconds);
    }
    notifyListeners();
  }

  double get eegAmplitudeMicroVolts => _eegAmplitudeMicroVolts;

  set eegAmplitudeMicroVolts(double value) {
    _eegAmplitudeMicroVolts = value;
    _preferences.setDouble(PreferenceKey.displayMaxAmplitude, value);
    notifyListeners();
  }
}
