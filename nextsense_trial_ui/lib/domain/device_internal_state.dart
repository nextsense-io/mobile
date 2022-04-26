// Fields list for the DeviceInternalState object received from the native
// layer.
import 'package:flutter/foundation.dart';

// These field keys must match with ones declared in java side
// in DeviceInternalState.java
enum DeviceInternalStateFields {
  // When the state was sampled in the hardware device.
  timestamp,
  // Battery level in millivolts.
  batteryMilliVolts,
  // If the device is currently busy processing a command.
  busy,
  // If a micro sd card is inserted in the device.
  uSdPresent,
  // If the earbuds hdmi cable is currently connected.
  hdmiCablePresent,
  // If the RTC clock time is set.
  rtcClockSet,
  // If the device is currently capturing samples from the earbuds.
  captureRunning,
  // If the device battery is charging.
  charging,
  // If the battery level is low.
  batteryLow,
  // If the device is logging captured samples to the sd card.
  uSdLoggingEnabled,
  // If the device detected an internal error and cannot operate anymore.
  internalErrorDetected,
  // How many samples were captured since the start of a capture.
  samplesCounter,
  // How many samples are in the BLE queue waiting to be transmitted.
  bleQueueBacklog,
  // How many samples were lost because the ble queue was full.
  lostSamplesCounter,
  // ble RSSI.
  bleRssi,
  // Boolean array indicating if a channel lead is considered to be off
  // (Impedance too high). Channels 1-8 in order.
  leadsOffPositive
}

class DeviceInternalState {

  DateTime timestamp;
  int batteryMilliVolts;
  bool busy;
  bool uSdPresent;
  bool hdmiCablePresent;
  bool rtcClockSet;
  bool captureRunning;
  bool charging;
  bool batteryLow;
  bool uSdLoggingEnabled;
  bool internalErrorDetected;
  int samplesCounter;
  int bleQueueBacklog;
  int lostSamplesCounter;
  int bleRssi;
  List<bool> leadsOffPositive;

  DeviceInternalState(Map<String, dynamic> values) :
      timestamp = DateTime.parse(values[describeEnum(
          DeviceInternalStateFields.timestamp)]),
      batteryMilliVolts = values[describeEnum(
          DeviceInternalStateFields.batteryMilliVolts)],
      busy = values[describeEnum(DeviceInternalStateFields.busy)],
      uSdPresent = values[describeEnum(DeviceInternalStateFields.uSdPresent)],
      hdmiCablePresent = values[describeEnum(
          DeviceInternalStateFields.hdmiCablePresent)],
      rtcClockSet = values[describeEnum(DeviceInternalStateFields.rtcClockSet)],
      captureRunning = values[describeEnum(
          DeviceInternalStateFields.captureRunning)],
      charging = values[describeEnum(DeviceInternalStateFields.charging)],
      batteryLow = values[describeEnum(DeviceInternalStateFields.batteryLow)],
      uSdLoggingEnabled = values[describeEnum(
          DeviceInternalStateFields.uSdLoggingEnabled)],
      internalErrorDetected =
          values[describeEnum(DeviceInternalStateFields.internalErrorDetected)],
      samplesCounter = values[describeEnum(
          DeviceInternalStateFields.samplesCounter)],
      bleQueueBacklog = values[describeEnum(
          DeviceInternalStateFields.bleQueueBacklog)],
      lostSamplesCounter =
          values[describeEnum(DeviceInternalStateFields.lostSamplesCounter)],
      bleRssi = values[describeEnum(DeviceInternalStateFields.bleRssi)],
      leadsOffPositive = new List<bool>.from(
          values[describeEnum(DeviceInternalStateFields.leadsOffPositive)])
  {}
}