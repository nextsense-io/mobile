import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class Device {
  String macAddress;
  String name;

  Device(this.macAddress, this.name);
}

enum DeviceState {
  connecting,
  connected,
  ready,
  disconnecting,
  disconnected
}

DeviceState deviceStateFromString(String str) {
  // Device state coming from Java side in upper case
  return DeviceState.values.firstWhere((e) => e.name == str.toLowerCase());
}

// Contains the currently connected devices for ease of use.
class DeviceManager {
  static final int connectionLostNotificationId = 2;
  static final String connectionLostTitle = 'Connection lost';
  static final String connectionLostBody = 'The connection with your '
      'NextSense device was lost. Please make sure it was not turned off by '
      'accident and make sure your phone is not more than a few meters away. '
      'It should reconnect automatically.';
  // It takes a maximum of about 1 second to find the device if it is already
  // powered up. 2 seconds gives enough safety and is not too long to wait if
  // the device is not powered on or is too far.
  static final Duration _scanTimeout = Duration(seconds: 2);

  final _notificationsManager = getIt<NotificationsManager>();
  final _authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceManager');

  Device? _connectedDevice;
  CancelListening? _cancelStateListening;
  CancelListening? _cancelInternalStateListening;

  ValueNotifier<DeviceState> deviceState =
      ValueNotifier(DeviceState.disconnected);
  ValueNotifier<DeviceInternalState?> deviceInternalState = ValueNotifier(null);
  Completer<bool> _deviceInternalStateAvailableCompleter = Completer<bool>();
  Completer<bool> _deviceReadyCompleter = Completer<bool>();
  Completer<bool> _scanFinishedCompleter = Completer<bool>();
  Device? _scannedDevice;
  Map<String, dynamic>? _deviceInternalStateValues;
  final _deviceInternalStateChangeController =
      StreamController<DeviceInternalStateEvent>.broadcast();
  Stream<DeviceInternalStateEvent> get deviceInternalStateChangeStream
      => _deviceInternalStateChangeController.stream;

  bool get deviceIsConnected => deviceState.value == DeviceState.ready;
  bool get deviceInternalStateAvailable => deviceInternalState.value != null;

  // Internal state shortcuts
  bool get isHdmiCablePresent =>
      deviceInternalState.value?.hdmiCablePresent ?? false;

  bool get isUSdPresent => deviceInternalState.value?.uSdPresent ?? false;

  // There is already paired device, which we could connect to
  bool get hadPairedDevice => getLastPairedDevice() != null;

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
    if (macAddress == null) {
      return null;
    }
    // TODO(alex): get device name for constructor?
    return Device(macAddress, "");
  }

  // Try connect to last paired device, returns true on success
  Future<bool> connectToLastPairedDevice() async {
    Device? lastPairedDevice = getLastPairedDevice();
    if (lastPairedDevice == null) {
      return false;
    }
    bool connected = false;

    CancelListening _cancelScanning =
        NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress =
          deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO, 'Found a device: ' + macAddress);
      if (macAddress == lastPairedDevice.macAddress) {
        String name = deviceAttributes[
          describeEnum(DeviceAttributesFields.name)];
        _scannedDevice = new Device(macAddress, name);
        _logger.log(Level.INFO, 'Last paired device found, reconnecting');
        _scanFinishedCompleter.complete(true);
      }
    });
    _logger.log(Level.FINE, 'Starting to wait on scan');
    await waitScanFinished(_scanTimeout);
    _cancelScanning();
    _logger.log(Level.FINE, 'finished waiting on scan');

    // Connect to device automatically if found
    if (_scannedDevice != null) {
      _scannedDevice = null;
      try {
        connected = await connectDevice(lastPairedDevice);
      } on PlatformException {}
    }
    if (connected) {
      _logger.log(Level.INFO, "Connected to last paired device "
          "${lastPairedDevice.macAddress}");
    } else {
      _logger.log(Level.WARNING, "Failed connect to last paired device "
          "${lastPairedDevice.macAddress}");
    }
    return connected;
  }

  Future<bool> waitScanFinished(Duration timeout) async {
    _scanFinishedCompleter = new Completer<bool>();
    new Timer(timeout, () {
      if (!_scanFinishedCompleter.isCompleted) {
        _scanFinishedCompleter.complete(_scannedDevice != null);
      }
    });
    return _scanFinishedCompleter.future;
  }

  Future<bool> waitDeviceReady(Duration timeout) async {
    _deviceReadyCompleter = new Completer<bool>();
    new Timer(timeout, () {
      if (!_deviceReadyCompleter.isCompleted) {
        _deviceReadyCompleter
            .complete(deviceState.value == DeviceState.ready);
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
        .hideAlertNotification(connectionLostNotificationId);
    NextsenseBase.disconnectDevice(getConnectedDevice()!.macAddress);
    deviceState.value = DeviceState.disconnected;
    _connectedDevice = null;
  }

  void _listenToState(String macAddress) {
    _cancelStateListening = NextsenseBase.listenToDeviceState((newDeviceState) {
      _logger.log(Level.INFO, 'Device state changed to ' + newDeviceState);
      if (_connectedDevice != null) {
        final DeviceState state = deviceStateFromString(newDeviceState);
        switch (state) {
          case DeviceState.disconnected:
            _onDeviceDisconnected();
            break;
          case DeviceState.ready:
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
        // AT this time only the boolean values need to propagate as events.
        if (oldValue is! bool) {
          return;
        }
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
    _notificationsManager.showAlertNotification(connectionLostNotificationId,
        connectionLostTitle, connectionLostBody);
    deviceState.value = DeviceState.disconnected;
  }

  void _onDeviceReady() {
    _notificationsManager
        .hideAlertNotification(connectionLostNotificationId);
    deviceState.value = DeviceState.ready;
    if (!_deviceReadyCompleter.isCompleted) {
      _deviceReadyCompleter.complete(true);
    }
  }
}
