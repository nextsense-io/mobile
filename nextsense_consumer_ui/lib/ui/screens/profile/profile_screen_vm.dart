import 'package:flutter/services.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/viewmodels/device_state_viewmodel.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreenViewModel extends DeviceStateViewModel {

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  String? get userId => _authManager.user!.getEmail() ?? _authManager.user!.getUsername()!;
  String? version = '';

  @override
  void init() async {
    super.init();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    setInitialised(true);
    notifyListeners();
  }

  Future disconnectDevice() async {
    await _deviceManager.manualDisconnect();
    await _authManager.user!..setLastPairedDeviceMacAddress(null)..save();
    notifyListeners();
  }

  Future logout() async {
    await _deviceManager.disconnectDevice();
    await _authManager.signOut();
  }

  Future exit() async {
    await _deviceManager.disconnectDevice();
    _deviceManager.dispose();
    NextsenseBase.setFlutterActivityActive(false);
    SystemNavigator.pop();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void onDeviceDisconnected() {
    notifyListeners();
  }

  @override
  void onDeviceReconnected() {
    notifyListeners();
  }
}