import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/kauai_proto/kauai_firmware_message.pb.dart';
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
  DeviceType? type;
  String? revision;
  String? serialNumber;
  String? firmwareVersionMajor;
  String? firmwareVersionMinor;
  String? firmwareVersionBuildNumber;
  String? earbudsType;
  String? earbudsRevision;
  String? earbudsSerialNumber;
  String? earbudsVersionMajor;
  String? earbudsVersionMinor;
  String? earbudsVersionBuildNumber;

  Device(this.macAddress, this.name, {this.type, this.revision, this.serialNumber,
    this.firmwareVersionMajor, this.firmwareVersionMinor, this.firmwareVersionBuildNumber,
    this.earbudsType, this.earbudsRevision, this.earbudsSerialNumber, this.earbudsVersionMajor,
    this.earbudsVersionMinor, this.earbudsVersionBuildNumber});
}

enum DeviceState { connecting, connected, ready, disconnecting, disconnected }

DeviceState deviceStateFromString(String str) {
  // Device state coming from Java side in upper case
  return DeviceState.values.firstWhere((e) => e.name == str.toLowerCase());
}

// Contains the currently connected devices for ease of use.
class DeviceManager {
  static final int connectionLostNotificationId = 2;
  static final String connectionLostTitle = 'Connection lost';
  static final String connectionLostBody = 'The connection with your NextSense device was lost. '
      'Please make sure it was not turned off by accident and make sure your phone is not more '
      'than a few meters away. It should reconnect automatically.';

  // It takes a maximum of about 1 second to find the device if it is already powered up. 2 seconds
  // gives enough safety and is not too long to wait if the device is not powered on or is too far.
  static final Duration _scanTimeout = Duration(seconds: 2);

  final _notificationsManager = getIt<NotificationsManager>();
  final _authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceManager');
  final _deviceInternalStateChangeController =
      StreamController<DeviceInternalStateEvent>.broadcast();

  ValueNotifier<DeviceState> deviceState = ValueNotifier(DeviceState.disconnected);
  ValueNotifier<DeviceInternalState?> deviceInternalState = ValueNotifier(null);

  Device? _connectedDevice;
  CancelListening? _cancelStateListening;
  CancelListening? _cancelEventsListening;
  CancelListening? _cancelInternalStateListening;
  Completer<bool> _deviceInternalStateAvailableCompleter = Completer<bool>();
  Completer<bool> _deviceReadyCompleter = Completer<bool>();
  Completer<bool> _scanFinishedCompleter = Completer<bool>();
  Timer? _requestDeviceStateTimer;
  Device? _scannedDevice;
  Map<String, dynamic>? _deviceInternalStateValues;

  Stream<DeviceInternalStateEvent> get deviceInternalStateChangeStream =>
      _deviceInternalStateChangeController.stream;
  bool get deviceIsReady => deviceState.value == DeviceState.ready;
  bool get deviceInternalStateAvailable => deviceInternalState.value != null;
  // Internal state shortcuts.
  // TODO(eric): Make this conditional on device type.
  bool get isHdmiCablePresent => deviceInternalState.value?.hdmiCablePresent ?? true;
  bool get isUSdPresent => deviceInternalState.value?.uSdPresent ?? true;
  // There is already a paired device that can be connected to if found.
  bool get hadPairedDevice => getLastPairedDevice() != null;

  Future<bool> connectDevice(Device device,
      {Duration timeout = const Duration(seconds: 10)}) async {
    _listenToState(device.macAddress);
    if (device.type == DeviceType.xenon) {
      _listenToInternalState();
    }
    _connectedDevice = device;
    await NextsenseBase.connectDevice(device.macAddress);
    // Check device state in case it is already READY (service was already running with a connected
    // device).
    deviceState.value = await _getDeviceState(device.macAddress);
    if (deviceState.value != DeviceState.ready) {
      bool deviceReady = await waitDeviceReady(timeout);
      if (!deviceReady) {
        _logger.log(Level.WARNING, 'Timeout waiting for ready state');
        await disconnectDevice();
        return false;
      }
    } else {
      _connectedDevice = await getDeviceInfo(_connectedDevice!);
    }
    if (_connectedDevice!.type == DeviceType.xenon) {
      NextsenseBase.requestDeviceStateUpdate(_connectedDevice!.macAddress);
      bool stateAvailable = await waitInternalStateAvailable(timeout);
      if (!stateAvailable) {
        _logger.log(Level.WARNING, 'Timeout waiting for internal state available');
        await disconnectDevice();
        return false;
      }
    } else if (_connectedDevice!.type == DeviceType.kauai) {
      _listenToEvents();
    }

    if (_connectedDevice!.type == DeviceType.xenon) {
      _requestStateChanges();
    }
    _authManager.user!
      ..setLastPairedDeviceMacAddress(_connectedDevice!.macAddress)
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

  Future<DeviceState> _getDeviceState(String macAddress) async {
    String deviceStateString = await NextsenseBase.getDeviceState(macAddress);
    return deviceStateFromString(deviceStateString);
  }

  // Try connect to last paired device, returns true on success
  Future<bool> connectToLastPairedDevice() async {
    Device? lastPairedDevice = getLastPairedDevice();
    if (lastPairedDevice == null) {
      return false;
    }
    bool connected = false;

    CancelListening _cancelScanning = NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress = deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO, 'Found a device: ' + macAddress);
      if (macAddress == lastPairedDevice.macAddress) {
        String name = deviceAttributes[describeEnum(DeviceAttributesFields.name)];
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
      try {
        connected = await connectDevice(_scannedDevice!);
      } on PlatformException catch (e) {
        _logger.log(
            Level.WARNING,
            "Failed to reconnect to last paired device: ${e.message}");
      }
    }
    if (connected) {
      _logger.log(Level.INFO, "Connected to last paired device ${lastPairedDevice.macAddress}");
    } else {
      _logger.log(
          Level.WARNING,
          "Failed connect to last paired device "
          "${lastPairedDevice.macAddress}");
    }
    _scannedDevice = null;
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
        _deviceReadyCompleter.complete(deviceState.value == DeviceState.ready);
      }
    });
    return _deviceReadyCompleter.future;
  }

  Future<bool> waitInternalStateAvailable(Duration timeout) async {
    _deviceInternalStateAvailableCompleter = new Completer<bool>();
    new Timer(timeout, () {
      if (!_deviceInternalStateAvailableCompleter.isCompleted) {
        _deviceInternalStateAvailableCompleter.complete(deviceInternalStateAvailable);
      }
    });
    return _deviceInternalStateAvailableCompleter.future;
  }

  Device? getConnectedDevice() {
    return _connectedDevice;
  }

  Future<bool> isConnectedDeviceStreaming() async {
    if (_connectedDevice != null) {
      return NextsenseBase.isDeviceStreaming(_connectedDevice!.macAddress);
    }
    return false;
  }

  Future manualDisconnect() async {
    await disconnectDevice();
    await _authManager.user!..setLastPairedDeviceMacAddress(null)..save();
  }

  Future disconnectDevice() async {
    _notificationsManager.hideAlertNotification(connectionLostNotificationId);
    if (getConnectedDevice() == null) {
      _logger.log(Level.FINE, "Trying to disconnect but no connected device");
      return;
    }
    _requestDeviceStateTimer?.cancel();
    _requestDeviceStateTimer = null;
    _cancelStateListening?.call();
    _cancelStateListening = null;
    _cancelEventsListening?.call();
    _cancelEventsListening = null;
    _cancelInternalStateListening?.call();
    _cancelInternalStateListening = null;
    try {
      await NextsenseBase.disconnectDevice(getConnectedDevice()!.macAddress);
    } on PlatformException {
      _logger.log(Level.WARNING, "Failed to disconnect.");
    }
    deviceState.value = DeviceState.disconnected;
    _connectedDevice = null;
  }

  Future<int> startStreaming(
      {bool? uploadToCloud,
      String? bigTableKey,
      String? dataSessionCode,
      String? earbudsConfig}) async {
    if (_connectedDevice == null) {
      throw Exception('No connected device');
    }
    int localSession = await NextsenseBase.startStreaming(_connectedDevice!.macAddress,
        uploadToCloud ?? false, bigTableKey, dataSessionCode, earbudsConfig);
    _requestDeviceStateTimer?.cancel();
    _requestDeviceStateTimer = null;
    return localSession;
  }

  Future stopStreaming() async {
    if (_connectedDevice == null) {
      _logger.log(Level.WARNING, 'Tried to stop streaming without a connected device.');
      return true;
    }
    await NextsenseBase.stopStreaming(_connectedDevice!.macAddress);
    if (_connectedDevice!.type == DeviceType.xenon) {
      _requestStateChanges();
    }
  }

  void dispose() {
    _requestDeviceStateTimer?.cancel();
    _cancelStateListening?.call();
    _cancelEventsListening?.call();
    _cancelInternalStateListening?.call();
  }

  void _listenToState(String macAddress) {
    if (_cancelStateListening != null) {
      _cancelStateListening?.call();
    }
    _cancelStateListening = NextsenseBase.listenToDeviceState((newDeviceState) {
      _logger.log(Level.INFO, 'Device state changed to ' + newDeviceState);
      if (_connectedDevice != null) {
        final DeviceState state = deviceStateFromString(newDeviceState);
        switch (state) {
          case DeviceState.disconnected:
            if (deviceState.value != DeviceState.disconnected) {
              _onDeviceDisconnected();
            }
            break;
          case DeviceState.ready:
            if (deviceState.value != DeviceState.ready) {
              _onDeviceReady();
            }
            break;
          default:
            break;
        }
      } else {
        if (deviceState.value == DeviceState.ready) {
          _logger.log(Level.WARNING, "State changed to READY but no connected device.");
        }
      }
    }, macAddress);
  }

  Future _requestStateChanges() async {
    if (_requestDeviceStateTimer != null) {
      return;
    }
    _requestDeviceStateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (_connectedDevice != null && deviceIsReady) {
          _logger.log(Level.FINE, 'Requesting device state update.');
          NextsenseBase.requestDeviceStateUpdate(_connectedDevice!.macAddress);
        }
      },
    );
  }

  void _listenToInternalState() {
    if (_cancelInternalStateListening != null) {
      _cancelInternalStateListening?.call();
    }
    _cancelInternalStateListening =
        NextsenseBase.listenToDeviceInternalState((newDeviceInternalStateJson) {
      _logger.log(Level.FINE, 'Device internal state changed');
      Map<String, dynamic> newStateValues = jsonDecode(newDeviceInternalStateJson);

      DeviceInternalState state = new DeviceInternalState(newStateValues);

      deviceInternalState.value = state;
      if (!_deviceInternalStateAvailableCompleter.isCompleted) {
        _deviceInternalStateAvailableCompleter.complete(true);
      }

      _detectInternalStateValueChange(newStateValues);
      _deviceInternalStateValues = newStateValues;
    });
  }

  void _listenToEvents() {
    if (_connectedDevice == null) {
      return;
    }
    if (_cancelEventsListening != null) {
      _cancelEventsListening?.call();
    }
    _cancelEventsListening =
        NextsenseBase.listenToDeviceEvents((deviceEventProtoBytes) {
          _logger.log(Level.FINE, 'Device event received');
          HostMessage hostMessage = HostMessage.fromBuffer(deviceEventProtoBytes);
          DeviceInternalStateEvent? event;
          switch (hostMessage.eventType) {
            case EventType.USB_CABLE_CONNECTED:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.usbCableConnected, true);
              break;
            case EventType.USB_CABLE_DISCONNECTED:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.usbCableDisconnected, true);
              break;
            case EventType.HDMI_CABLE_DISCONNECTED:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.hdmiCableDisconnected, true);
              break;
            case EventType.HDMI_CABLE_CONNECTED:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.hdmiCableConnected, true);
              break;
            case EventType.MEMORY_STORAGE_FULL:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.uSdFull, true);
              break;
            case EventType.BATTERY_LOW:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.batteryLow, true);
              break;
            case EventType.POWERING_OFF:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.poweringOff, true);
              break;
            case EventType.GOING_TO_STANDBY:
              event = DeviceInternalStateEvent.create(
                  DeviceInternalStateEventType.poweringOff, true);
              break;
          }
          if (event != null) {
            _deviceInternalStateChangeController.add(event);
          }
        }, _connectedDevice!.macAddress);
  }

  // Whenever a new state is received, compare it to the one that is cached and
  // generate a state transition event whenever one of the boolean flags
  // are changed (like low battery, earbuds disconnected, etc…)
  void _detectInternalStateValueChange(Map<String, dynamic> newStateValues) {
    if (_deviceInternalStateValues != null) {
      for (var key in newStateValues.keys) {
        var oldValue = _deviceInternalStateValues![key];
        // At this time only the boolean values need to propagate as events.
        if (oldValue is! bool) {
          continue;
        }
        var newValue = newStateValues[key];
        // Compare DeviceInternalState fields
        bool equal(dynamic a, dynamic b) {
          if (a is List && b is List) {
            return listEquals(a, b);
          }
          return oldValue == newValue;
        }

        if (_deviceInternalStateValues!.containsKey(key) && !equal(oldValue, newValue)) {
          final event = DeviceInternalStateEvent.createFromInternalStateField(key, newValue);
          _deviceInternalStateChangeController.add(event);
        }
      }
    }
  }

  void _onDeviceDisconnected() {
    // Disconnected without being requested by the user.
    _logger.log(Level.INFO, "Device disconnected without being requested by the user.");
    showAlertNotification(connectionLostNotificationId, connectionLostTitle, connectionLostBody);
    deviceState.value = DeviceState.disconnected;
    _requestDeviceStateTimer?.cancel();
    _requestDeviceStateTimer = null;
  }

  Future<Device> getDeviceInfo(Device connectedDevice) async {
    Map<String, dynamic> deviceAttributes = await NextsenseBase.getDeviceInfo(
        connectedDevice.macAddress);
    String? deviceTypeString = deviceAttributes[describeEnum(DeviceAttributesFields.type)];
    DeviceType? deviceType = deviceTypeString != null ?
        DeviceType.values.byName(deviceTypeString.toLowerCase()) : null;
    return new Device(connectedDevice.macAddress, connectedDevice.name,
        type: deviceType,
        revision: deviceAttributes[describeEnum(DeviceAttributesFields.revision)],
        serialNumber: deviceAttributes[describeEnum(DeviceAttributesFields.serialNumber)],
        firmwareVersionMajor:
            deviceAttributes[describeEnum(DeviceAttributesFields.firmwareVersionMajor)],
        firmwareVersionMinor:
            deviceAttributes[describeEnum(DeviceAttributesFields.firmwareVersionMinor)],
        firmwareVersionBuildNumber:
            deviceAttributes[describeEnum(DeviceAttributesFields.firmwareVersionBuildNumber)],
        earbudsType: deviceAttributes[describeEnum(DeviceAttributesFields.earbudsType)],
        earbudsRevision: deviceAttributes[describeEnum(DeviceAttributesFields.earbudsRevision)],
        earbudsSerialNumber:
            deviceAttributes[describeEnum(DeviceAttributesFields.earbudsSerialNumber)],
        earbudsVersionMajor:
            deviceAttributes[describeEnum(DeviceAttributesFields.earbudsVersionMajor)],
        earbudsVersionMinor:
            deviceAttributes[describeEnum(DeviceAttributesFields.earbudsVersionMinor)],
        earbudsVersionBuildNumber:
            deviceAttributes[describeEnum(DeviceAttributesFields.earbudsVersionBuildNumber)]);
  }

  void _onDeviceReady() async {
    _notificationsManager.hideAlertNotification(connectionLostNotificationId);
    _connectedDevice = await getDeviceInfo(_connectedDevice!);
    deviceState.value = DeviceState.ready;
    if (!_deviceReadyCompleter.isCompleted) {
      _deviceReadyCompleter.complete(true);
    } else {
      _logger.log(Level.INFO, 'Reconnecting.');
      if (_connectedDevice!.type == DeviceType.xenon) {
        _requestStateChanges();
      }
    }
  }
}
