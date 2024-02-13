import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/viewmodels/device_state_viewmodel.dart';
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

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void onDeviceDisconnected() {
    // TODO(eric): implement onDeviceDisconnected
  }

  @override
  void onDeviceReconnected() {
    // TODO(eric): implement onDeviceReconnected
  }
}