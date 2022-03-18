import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

abstract class DeviceStateViewModelInterface extends ChangeNotifier {
  void onDeviceDisconnected();
  void onDeviceReconnected();
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event);
}

/*
 * This model is base for all UI view-models that are going to deal
 * with device state or device internal state
 */
abstract class DeviceStateViewModel
    extends DeviceStateViewModelInterface {

  final CustomLogPrinter _logger = CustomLogPrinter('DeviceStateViewModel');
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  DeviceState get deviceState => _deviceManager.deviceState.value;
  bool get deviceIsConnected => deviceState == DeviceState.READY;

  StreamSubscription<DeviceInternalStateEvent>?
    _deviceInternalStateChangesSubscription;

  // Internal state shortcuts
  bool get isHdmiCablePresent => _deviceManager.isHdmiCablePresent;
  bool get isUSdPresent => _deviceManager.isUSdPresent;

  void init() {
    _deviceManager.deviceState.addListener(_onDeviceStateChanged);

    _deviceInternalStateChangesSubscription = _deviceManager
        .deviceInternalStateChangeStream.listen(onDeviceInternalStateChanged);
  }

  void _onDeviceStateChanged() {
    switch (deviceState) {
      case DeviceState.DISCONNECTED:
        onDeviceDisconnected();
        break;
      case DeviceState.READY:
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
    super.dispose();
  }

  @override
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event) {
    _logger.log(Level.INFO, "onDeviceInternalStateChanged: $event");
    notifyListeners();
  }
}