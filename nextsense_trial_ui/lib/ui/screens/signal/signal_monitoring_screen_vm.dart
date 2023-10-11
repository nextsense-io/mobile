import 'dart:async';
import 'dart:math';

import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_settings.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/algorithms.dart';
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

class PlotDataPoint {
  final double index;
  final double value;

  PlotDataPoint(this.index, this.value);
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
  static const Duration _filterSettleTime = Duration(seconds: 2);
  static const double defaultMaxAmplitudeMicroVolts = 50;
  static const double _defaultLowPassFreq = 1;
  static const double _defaultHighPassFreq = 55;
  static const double _defaultPowerLineFreq = 60;

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final _preferences = getIt<Preferences>();

  Device? device;
  DeviceSettings? _deviceSettings;
  String? _selectedChannel;
  DataType _dataType = DataType.eeg;
  SignalProcessing _eegSignalProcessing = SignalProcessing.filtered;
  double _powerLineFrequency = _defaultPowerLineFreq;
  double _lowCutFrequency = _defaultLowPassFreq;
  double _highCutFrequency = _defaultHighPassFreq;
  Duration timeWindowMin = _eegTimeWindowMin;
  Duration timeWindowMax = _eegTimeWindowMax;
  Duration _graphTimeWindow = _eegTimeWindowDefault;
  List<String> eegChannelList = [];
  int samplesToShow = 1250;
  double streamingFrequencyHz = 250;
  double _eegAmplitudeMicroVolts = _defaultMaxAmplitudeMicroVolts;
  List<AccelerationData> accData = [];
  List<PlotDataPoint> eegData = [];
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
    updateFilterSettings();
    _updateTimeSlider();
    if (device != null && _deviceManager.deviceIsReady) {
      _deviceSettings = DeviceSettings(await NextsenseBase.getDeviceSettings(device!.macAddress));
      dataType = DataType.create(_preferences.getString(PreferenceKey.displayDataType));
      eegChannelList = _deviceSettings!.enabledChannels;
      String userSelectedChannel = _preferences.getString(PreferenceKey.displaySelectedChannel) ??
          eegChannelList[0];
      if (eegChannelList.contains(userSelectedChannel)) {
        selectedChannel = userSelectedChannel;
      } else {
        selectedChannel = eegChannelList[0];
      }
      await _deviceManager.startStreaming();
      _screenRefreshTimer = new Timer.periodic(_refreshInterval, _updateScreen);
    }
    setBusy(false);
    setInitialised(true);
    notifyListeners();
  }

  @override
  void dispose() async {
    _screenRefreshTimer?.cancel();
    if (device != null && _deviceManager.deviceIsReady) {
      await _deviceManager.stopStreaming();
    }
    super.dispose();
  }

  void updateFilterSettings() {
    _eegSignalProcessing = SignalProcessing.create(
        _preferences.getString(PreferenceKey.eegSignalFilterType));
    _powerLineFrequency =
        _preferences.getDouble(PreferenceKey.powerLineFrequency) ?? _defaultPowerLineFreq;
    _lowCutFrequency = _preferences.getDouble(PreferenceKey.lowCutFrequency) ??
        _defaultLowPassFreq;
    _highCutFrequency = _preferences.getDouble(PreferenceKey.highCutFrequency) ??
        _defaultHighPassFreq;
  }

  Future _getAccData() async {
    List<int> timestamps = await NextsenseBase.getTimestampsData(
        macAddress: device!.macAddress, duration: graphTimeWindow);
    List<int> accXData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
        channelName: 'x', duration: graphTimeWindow, fromDatabase: false);
    List<int> accYData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
        channelName: 'y', duration: graphTimeWindow, fromDatabase: false);
    List<int> accZData = await NextsenseBase.getAccChannelData(macAddress: device!.macAddress,
        channelName: 'z', duration: graphTimeWindow, fromDatabase: false);
    List<AccelerationData> accelerations = [];
    for (int i = 0; i < timestamps.length; ++i) {
      if (accXData.length <= i || accYData.length <= i || accZData.length <= i) {
        break;
      }
      accelerations.add(AccelerationData(x: accXData[i].toInt(), y: accYData[i].toInt(),
          z: accZData[i].toInt(), timestamp:
          DateTime.fromMillisecondsSinceEpoch(timestamps[i].toInt())));
    }
    accData = accelerations;
  }

  Future _getEegData() async {
    // Add some data to be able to hide the filter settle time in the result.
    List<double> currentEegData;
    // Filter the data.
    if (_eegSignalProcessing == SignalProcessing.filtered) {
      currentEegData = await NextsenseBase.getChannelData(macAddress: device!.macAddress,
          channelName: _selectedChannel!, duration: _graphTimeWindow + _filterSettleTime,
          fromDatabase: false);
      double samplingFrequencyHz = _deviceSettings!.eegSamplingRate!;
      // Make sure the high cut off is not higher than the actual signal.
      double effectiveHighCutFreq = _highCutFrequency;
      if (samplingFrequencyHz / 2 < _highCutFrequency) {
        effectiveHighCutFreq = samplingFrequencyHz / 2 - 1;
      }
      currentEegData = Algorithms.filterNotch(
          currentEegData, samplingFrequencyHz, _powerLineFrequency.round(), /*notchWidth=*/ 4,
          /*order=*/ 2);
      currentEegData = Algorithms.filterBandpass(
          currentEegData, samplingFrequencyHz,_lowCutFrequency, effectiveHighCutFreq, /*order=*/ 2);
      // Remove some part of the data to account for the filter settle time.
      currentEegData =
          currentEegData.sublist([0, currentEegData.length - samplesToShow].reduce(max));
    } else {
      currentEegData = await NextsenseBase.getChannelData(macAddress: device!.macAddress,
          channelName: _selectedChannel!, duration: _graphTimeWindow,
          fromDatabase: false);
    }
    // Display the X axis in seconds.
    double samplesToTimeRatio = _graphTimeWindow.inSeconds / currentEegData.length;
    // Load an array with the data indexed by relative seconds.
    List<PlotDataPoint> eegData = [];
    for (int i = 0; i < currentEegData.length; ++i) {
      eegData.add(new PlotDataPoint(i * samplesToTimeRatio, currentEegData[i]));
    }
    this.eegData = eegData;
  }

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
    if (dataType == DataType.eeg) {
      _getEegData();
    } else {
      _getAccData();
    }
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
    print("data type: $value");
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
