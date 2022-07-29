import 'dart:async';

import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

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

class AccelerationPlotDataViewModel extends DeviceStateViewModel {

  static const Duration _refreshInterval = Duration(milliseconds: 100);

  String deviceMacAddress;
  Duration timeWindow;
  List<AccelerationData>? accData = [];
  Timer? _screenRefreshTimer;

  AccelerationPlotDataViewModel({required this.deviceMacAddress, required this.timeWindow});

  @override
  void init() async {
    super.init();
    _screenRefreshTimer = new Timer.periodic(_refreshInterval, _updateScreen);
  }

  @override
  void dispose() async {
    _screenRefreshTimer?.cancel();
    super.dispose();
  }

  Future _getAccData() async {
    List<int> timestamps = await NextsenseBase.getTimestampsData(
        macAddress: deviceMacAddress, duration: timeWindow);
    List<int> accXData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'x', duration: timeWindow, fromDatabase: false);
    List<int> accYData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'y', duration: timeWindow, fromDatabase: false);
    List<int> accZData = await NextsenseBase.getAccChannelData(macAddress: deviceMacAddress,
        channelName: 'z', duration: timeWindow, fromDatabase: false);
    List<AccelerationData> accelerations = [];
    for (int i = 0; i < timestamps.length; ++i) {
      accelerations.add(AccelerationData(x: accXData[i].toInt(), y: accYData[i].toInt(),
          z: accZData[i].toInt(), timestamp:
          DateTime.fromMillisecondsSinceEpoch(timestamps[i].toInt())));
    }
    accData = accelerations;
  }

  void _updateScreen(Timer timer) {
    print("updating acc screen");
    _getAccData();
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
}
