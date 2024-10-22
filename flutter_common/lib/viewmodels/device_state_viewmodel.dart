import 'dart:async';

import 'package:flutter_common/di.dart';
import 'package:flutter_common/domain/device_internal_state_event.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';


abstract class DeviceStateViewModelInterface {
  void onDeviceDisconnected();
  void onDeviceReconnected();
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event);
}

/*
 * This model is base for all UI view-models that are going to deal
 * with device state or device internal state
 */
abstract class DeviceStateViewModel extends ViewModel implements DeviceStateViewModelInterface {

  final CustomLogPrinter _logger = CustomLogPrinter('DeviceStateViewModel');
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  bool _mounted = false;

  bool get mounted => _mounted;
  DeviceState get deviceState => _deviceManager.deviceState.value;
  bool get isHdmiCablePresent => _deviceManager.isHdmiCablePresent;
  bool get isUSdPresent => _deviceManager.isUSdPresent;
  bool get deviceIsConnected => deviceState == DeviceState.ready;
  bool get deviceCanRecord => deviceIsConnected && isHdmiCablePresent && isUSdPresent;

  StreamSubscription<DeviceInternalStateEvent>? _deviceInternalStateChangesSubscription;

  @override
  void init() {
    super.init();
    _deviceManager.deviceState.addListener(_onDeviceStateChanged);
    _deviceInternalStateChangesSubscription = _deviceManager
        .deviceInternalStateChangeStream.listen(onDeviceInternalStateChanged);
  }

  void _onDeviceStateChanged() {
    switch (deviceState) {
      case DeviceState.disconnected:
        onDeviceDisconnected();
        break;
      case DeviceState.ready:
        onDeviceReconnected();
        break;
      default:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceManager.deviceState.removeListener(_onDeviceStateChanged);
    _deviceInternalStateChangesSubscription?.cancel();
    if (mounted) {
      super.dispose();
      _mounted = false;
    }
  }

  @override
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event) {
    _logger.log(Level.INFO, "onDeviceInternalStateChanged: $event");
    notifyListeners();
  }
}