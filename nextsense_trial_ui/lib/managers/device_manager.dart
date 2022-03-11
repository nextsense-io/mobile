import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class Device {
  String macAddress;
  String name;

  Device(this.macAddress, this.name);
}

enum DeviceState {
  CONNECTING,
  CONNECTED,
  READY,
  DISCONNECTING,
  DISCONNECTED
}

DeviceState deviceStateFromString(String str) {
  return DeviceState.values.firstWhere((e) => e.name == str);
}

// Contains the currently connected devices for ease of use.
class DeviceManager {
  static final int CONNECTION_LOST_NOTIFICATION_ID = 2;
  static final String CONNECTION_LOST_TITLE = 'Connection lost';
  static final String CONNECTION_LOST_BODY = 'The connection with your '
      'NextSense device was lost. Please make sure it was not turned off by '
      'accident and make sure your phone is not more than a few meters away. '
      'It should reconnect automatically.';

  final NotificationsManager _notificationsManager =
      GetIt.instance.get<NotificationsManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceManager');

  Device? _connectedDevice;
  CancelListening? _cancelStateListening;
  CancelListening? _cancelInternalStateListening;

  ValueNotifier<DeviceState> deviceState = ValueNotifier(DeviceState.READY);
  ValueNotifier<DeviceInternalState> deviceInternalState = ValueNotifier(DeviceInternalState.initial());
  bool get deviceIsConnected => deviceState.value == DeviceState.READY;

  // Internal state shortcuts
  bool get isHdmiCablePresent => deviceInternalState.value.hdmiCablePresent;
  bool get isUSdPresent => deviceInternalState.value.uSdPresent;

  void setConnectedDevice(Device? device) {
    if (device != null) {
      _listenToState(device.macAddress);
      _listenToInternalState();
      NextsenseBase.requestDeviceStateUpdate(device.macAddress);
    } else {
      _cancelStateListening?.call();
      _cancelInternalStateListening?.call();
    }
    _connectedDevice = device;
  }

  Device? getConnectedDevice() {
    return _connectedDevice;
  }

  void disconnectDevice() {
    if (getConnectedDevice() == null) {
      return;
    }
    _cancelStateListening?.call();
    _cancelInternalStateListening?.call();
    _notificationsManager.hideAlertNotification(
        CONNECTION_LOST_NOTIFICATION_ID);
    NextsenseBase.disconnectDevice(getConnectedDevice()!.macAddress);
    setConnectedDevice(null);
  }

  void _listenToState(String macAddress) {
    _cancelStateListening = NextsenseBase.listenToDeviceState((newDeviceState) {
      _logger.log(Level.INFO, 'Device state changed to ' + newDeviceState);
      if (_connectedDevice != null) {
        final DeviceState state = deviceStateFromString(newDeviceState);
        switch (state) {
          case DeviceState.DISCONNECTED: _onDeviceDisconnected(); break;
          case DeviceState.READY: _onDeviceReady(); break;
          default: break;
        }
      }
    }, macAddress);
  }

  void _listenToInternalState() {
    _cancelInternalStateListening =
        NextsenseBase.listenToDeviceInternalState((newDeviceInternalStateJson) {
      _logger.log(Level.FINE, 'Device internal state changed');
      if (_connectedDevice != null) {
        Map<String, dynamic> deviceInternalStateValues = jsonDecode(newDeviceInternalStateJson);
        _logger.log(Level.FINE, deviceInternalStateValues);
        DeviceInternalState state = new DeviceInternalState(deviceInternalStateValues);
        // TODO(eric): Implement state manager to propagate events and keep
        //             state.
        deviceInternalState.value = state;
      }
    });
  }

  void _onDeviceDisconnected() {
    // Disconnected without being requested by the user.
    _notificationsManager.showAlertNotification(
        CONNECTION_LOST_NOTIFICATION_ID, CONNECTION_LOST_TITLE,
        CONNECTION_LOST_BODY, /*payload=*/'');

    deviceState.value = DeviceState.DISCONNECTED;
  }

  void _onDeviceReady() {
    _notificationsManager.hideAlertNotification(
        CONNECTION_LOST_NOTIFICATION_ID);

    deviceState.value = DeviceState.READY;
  }
}
