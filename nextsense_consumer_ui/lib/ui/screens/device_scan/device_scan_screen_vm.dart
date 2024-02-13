import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';

enum ScanningState {
  NO_BLUETOOTH,
  SCANNING_NO_RESULTS,
  SCANNING_WITH_RESULTS,
  FINISHED_SCAN,
  NOT_FOUND_OR_ERROR,
  CONNECTING,
  CONNECTED
}

class DeviceScanScreenViewModel extends ViewModel {
  static const Duration _scanTimeout = Duration(seconds: 30);

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final bool autoConnect;
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceScanScreen');

  Map<String, Map<String, dynamic>> scanResultsMap = {};

  // Starts scanning when opened.
  ScanningState scanningState = ScanningState.SCANNING_NO_RESULTS;
  CancelListening? _cancelScanning;
  Timer? _stopScanningTimer;

  DeviceScanScreenViewModel({this.autoConnect = false});

  @override
  void init() {
    _logger.log(Level.INFO, 'Initializing state.');
    super.init();
    startScanIfPossible();
  }

  Future<bool> startScanIfPossible() async {
    if (!await NextsenseBase.isBluetoothEnabled()) {
      scanningState = ScanningState.NO_BLUETOOTH;
      notifyListeners();
      return false;
    } else {
      startScan();
      return true;
    }
  }

  @override
  void dispose() {
    _logger.log(Level.INFO, 'Disposing.');
    _stopScanningTimer?.cancel();
    _cancelScanning?.call();
    super.dispose();
  }

  void startScan() async {
    scanResultsMap.clear();
    notifyListeners();
    if (_deviceManager.getConnectedDevice() != null) {
      _logger.log(
          Level.INFO, 'Disconnecting device in case it is trying to reconnect automatically');
      await _deviceManager.disconnectDevice();
    }
    _logger.log(Level.INFO, 'Starting Bluetooth scan.');
    scanningState = ScanningState.SCANNING_NO_RESULTS;
    notifyListeners();
    _stopScanningTimer = Timer.periodic(
      _scanTimeout,
      (timer) {
        _cancelScanning?.call();
        if (scanResultsMap.isEmpty) {
          _logger.log(Level.FINE, 'Scanning timeout.');
          scanningState = ScanningState.NOT_FOUND_OR_ERROR;
        } else {
          scanningState = ScanningState.FINISHED_SCAN;
        }
        notifyListeners();
      },
    );
    _cancelScanning = NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress = deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO,
          'Found a device: ${deviceAttributes[describeEnum(DeviceAttributesFields.name)]}');
      scanResultsMap[macAddress] = deviceAttributes;
      // This flags let the device list start getting displayed.
      scanningState = ScanningState.SCANNING_WITH_RESULTS;

      // Connect to device automatically
      if (_authManager.getLastPairedMacAddress() == macAddress) {
        connectToDevice(deviceAttributes);
      }
      notifyListeners();
    });
  }

  connectToDevice(Map<String, dynamic> result) async {
    _stopScanningTimer?.cancel();
    Device device = Device(result[describeEnum(DeviceAttributesFields.macAddress)],
        result[describeEnum(DeviceAttributesFields.name)]);
    _logger.log(Level.INFO, 'Connecting to device: ${device.macAddress}');
    _cancelScanning?.call();
    scanningState = ScanningState.CONNECTING;
    notifyListeners();
    try {
      bool connected = await _deviceManager.connectDevice(device);
      if (connected) {
        _authManager.user!
          ..setLastPairedDeviceMacAddress(device.macAddress)
          ..save();
        scanningState = ScanningState.CONNECTED;
        _logger.log(Level.INFO, 'Connected to device: ${device.macAddress}');
      } else {
        setError('Connection error');
      }
      // TODO(eric): Check if needed for push notifications?
      // _logger.log(Level.INFO, "Navigate to next route");
      // bool navigated = await _navigation.navigateToNextRoute();
    } on PlatformException catch (e) {
      _logger.log(Level.INFO, "Failed to connect to device: ${e.message}");
      scanningState = ScanningState.NOT_FOUND_OR_ERROR;
      setError(e.message);
    }
    notifyListeners();
  }
}
