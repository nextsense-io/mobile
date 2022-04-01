import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
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

  final _notificationsManager = getIt<NotificationsManager>();
  final _authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceManager');

  Device? _connectedDevice;
  CancelListening? _cancelStateListening;
  CancelListening? _cancelInternalStateListening;

  ValueNotifier<DeviceState> deviceState =
      ValueNotifier(DeviceState.DISCONNECTED);
  ValueNotifier<DeviceInternalState?> deviceInternalState = ValueNotifier(null);
  Completer<bool> _deviceInternalStateAvailableCompleter = Completer<bool>();
  Completer<bool> _deviceReadyCompleter = Completer<bool>();
  Map<String, dynamic>? _deviceInternalStateValues;
  final _deviceInternalStateChangeController =
      StreamController<DeviceInternalStateEvent>.broadcast();
  Stream<DeviceInternalStateEvent> get deviceInternalStateChangeStream
      => _deviceInternalStateChangeController.stream;

  bool get deviceIsConnected => deviceState.value == DeviceState.READY;
  bool get deviceInternalStateAvailable => deviceInternalState.value != null;

  // Internal state shortcuts
  bool get isHdmiCablePresent =>
      deviceInternalState.value?.hdmiCablePresent ?? false;

  bool get isUSdPresent => deviceInternalState.value?.uSdPresent ?? false;

  Future<bool> connectDevice(Device device,
      {Duration timeout = const Duration(seconds: 10)}) async {
    _listenToState(device.macAddress);
    _listenToInternalState();
    await NextsenseBase.connectDevice(device.macAddress);
    _connectedDevice = device;
    bool deviceReady = await waitDeviceReady(timeout);
    if (!deviceReady) {
      _connectedDevice = null;
      return false;
    }
    NextsenseBase.requestDeviceStateUpdate(device.macAddress);
    bool stateAvailable = await waitInternalStateAvailable(timeout);
    if (!stateAvailable) {
      _connectedDevice = null;
      return false;
    }

    _authManager.user!
      ..setLastPairedDeviceMacAddress(device.macAddress)
      ..save();

    return true;
  }

  Device? getLastPairedDevice() {
    final userEntity = _authManager.user!;
    final macAddress = userEntity.getLastPairedDeviceMacAddress();
    if (macAddress == null) return null;
    // TODO(alex): get device name for constructor?
    return Device(macAddress, "");
  }

  Future<bool> connectLastPairedDevice() async {
    Device? lastPairedDevice = getLastPairedDevice();
    if (lastPairedDevice == null)
      return false;
    bool connected = false;
    try {
      connected = await connectDevice(lastPairedDevice);
    } on PlatformException {
    }
    if (connected) {
      _logger.log(Level.INFO, "Connected to last paired device "
          "${lastPairedDevice.macAddress}");
    }
    else {
      _logger.log(Level.WARNING, "Failed connect to last paired device "
          "${lastPairedDevice.macAddress}");
    }
    return connected;
  }

  Future<bool> waitDeviceReady(Duration timeout) async {
    _deviceReadyCompleter = new Completer<bool>();
    new Timer(timeout, () {
      if (!_deviceReadyCompleter.isCompleted) {
        _deviceReadyCompleter
            .complete(deviceState.value == DeviceState.READY);
      }
    });
    return _deviceReadyCompleter.future;
  }

  Future<bool> waitInternalStateAvailable(Duration timeout) async {
    _deviceInternalStateAvailableCompleter = new Completer<bool>();
    new Timer(timeout, () {
      if (!_deviceInternalStateAvailableCompleter.isCompleted) {
        _deviceInternalStateAvailableCompleter
            .complete(deviceInternalStateAvailable);
      }
    });
    return _deviceInternalStateAvailableCompleter.future;
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
    _notificationsManager
        .hideAlertNotification(CONNECTION_LOST_NOTIFICATION_ID);
    NextsenseBase.disconnectDevice(getConnectedDevice()!.macAddress);
    _cancelStateListening?.call();
    _cancelInternalStateListening?.call();
    _connectedDevice = null;
  }

  void _listenToState(String macAddress) {
    _cancelStateListening = NextsenseBase.listenToDeviceState((newDeviceState) {
      _logger.log(Level.INFO, 'Device state changed to ' + newDeviceState);
      if (_connectedDevice != null) {
        final DeviceState state = deviceStateFromString(newDeviceState);
        switch (state) {
          case DeviceState.DISCONNECTED:
            _onDeviceDisconnected();
            break;
          case DeviceState.READY:
            _onDeviceReady();
            break;
          default:
            break;
        }
      }
    }, macAddress);
  }

  void _listenToInternalState() {
    _cancelInternalStateListening =
        NextsenseBase.listenToDeviceInternalState((newDeviceInternalStateJson) {
      _logger.log(Level.FINE, 'Device internal state changed');
      Map<String, dynamic> newStateValues =
          jsonDecode(newDeviceInternalStateJson);

      DeviceInternalState state =
          new DeviceInternalState(newStateValues);

      deviceInternalState.value = state;
      if (!_deviceInternalStateAvailableCompleter.isCompleted) {
        _deviceInternalStateAvailableCompleter.complete(true);
      }

      _detectInternalStateValueChange(newStateValues);
      _deviceInternalStateValues = newStateValues;
    });
  }

  // Whenever a new state is received, compare it to the one that is cached and
  // generate a state transition event whenever one of the boolean flags
  // are changed (like low battery, earbuds disconnected, etc…)
  void _detectInternalStateValueChange(Map<String, dynamic> newStateValues) {
    if (_deviceInternalStateValues != null) {
      for (var key in newStateValues.keys) {
        var oldValue = _deviceInternalStateValues![key];
        var newValue = newStateValues[key];
        // Compare DeviceInternalState fields
        bool equal(dynamic a, dynamic b) {
          if (a is List && b is List) {
            return listEquals(a, b);
          }
          return oldValue == newValue;
        }
        if (_deviceInternalStateValues!.containsKey(key)
            && !equal(oldValue, newValue)) {
          final event = DeviceInternalStateEvent.create(key, newValue);
          _deviceInternalStateChangeController.add(event);
        }
      }
    }
  }

  void _onDeviceDisconnected() {
    // Disconnected without being requested by the user.
    _notificationsManager.showAlertNotification(CONNECTION_LOST_NOTIFICATION_ID,
        CONNECTION_LOST_TITLE, CONNECTION_LOST_BODY, /*payload=*/'');
    deviceState.value = DeviceState.DISCONNECTED;
  }

  void _onDeviceReady() {
    _notificationsManager
        .hideAlertNotification(CONNECTION_LOST_NOTIFICATION_ID);
    deviceState.value = DeviceState.READY;
    if (!_deviceReadyCompleter.isCompleted) {
      _deviceReadyCompleter.complete(true);
    }
  }
}
