import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/config.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class DeviceScanScreenViewModel extends ViewModel {
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final Navigation _navigation = getIt<Navigation>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceScanScreen');

  Map<String, Map<String, dynamic>> scanResultsMap = new Map();
  bool isScanning = false;
  bool isConnecting = false;
  int _scanningCount = 0;
  CancelListening? _cancelScanning;

  @override
  void init() {
    _logger.log(Level.INFO, 'Initializing state.');
    super.init();
    startScan();
  }

  @override
  void dispose() {
    _logger.log(Level.INFO, 'Disposing.');
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
    isScanning = true;
    notifyListeners();
    _cancelScanning = NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress = deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO,
        'Found a device: ' + deviceAttributes[describeEnum(DeviceAttributesFields.name)]);
      scanResultsMap[macAddress] = deviceAttributes;
      // This flags let the device list start getting displayed.
      isScanning = false;

      // Connect to device automatically
      if (Config.autoConnectAfterScan) {
        connectToDevice(deviceAttributes);
      }
      notifyListeners();
    });
  }

  connectToDevice(Map<String, dynamic> result) async {
    Device device = new Device(result[describeEnum(DeviceAttributesFields.macAddress)],
        result[describeEnum(DeviceAttributesFields.name)]);
    _logger.log(Level.INFO, 'Connecting to device: ' + device.macAddress);
    _cancelScanning?.call();
    isConnecting = true;
    notifyListeners();
    try {
      bool connected = await _deviceManager.connectDevice(device);
      _logger.log(Level.INFO, "Connected: ${connected}");
      if (connected) {
        if (_navigation.canPop()) {
          _logger.log(Level.INFO, "Popped route");
          _navigation.pop();
        }
        // TODO(eric): Check in study manager if need to show this.
        if (false) {
          _navigation.navigateTo(StudyIntroScreen.id, replace: true);
        } else {
          _logger.log(Level.INFO, "Navigate to next route");
          bool navigated = await _navigation.navigateToNextRoute();
          if (!navigated) {
            _logger.log(Level.INFO, "Navigate to dashboard");
            _navigation.navigateTo(DashboardScreen.id, replace: true);
          }
        }
      } else {
        startScan();
        setError('Connection error');
      }
    } on PlatformException catch (e) {
      startScan();
      setError(e.message);
    }
    isConnecting = false;
    notifyListeners();
    _logger.log(Level.INFO, 'Connected to device: ' + device.macAddress);
  }
}