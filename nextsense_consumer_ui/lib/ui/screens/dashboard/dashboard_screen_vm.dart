import 'dart:async';

import 'package:flutter_common/managers/device_manager.dart';
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/device_state_viewmodel.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/data_manager.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final DataManager _dataManager = getIt<DataManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final studyDayChangeStream = StreamController<int>.broadcast();
  bool dataInitialized = false;

  @override
  void init() async {
    super.init();
    await loadData();
  }

  Future loadData() async {
    clearErrors();
    notifyListeners();
    setBusy(true);
    try {
      if (!_dataManager.userDataLoaded) {
        bool success = await _dataManager.loadUserData();
        if (!success) {
          _logger.log(Level.WARNING, 'Failed to load user. Fallback to signup');
          logout();
          return;
        }
      }
      dataInitialized = true;
    } catch (e, stacktrace) {
      _logger.log(Level.SEVERE, 'Failed to load dashboard data: ${e.toString()}, '
          '${stacktrace.toString()}');
      setError("Failed to load data. Please contact support");
      setBusy(false);
      return;
    }
    setBusy(false);
  }

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
  }

  @override
  void onDeviceDisconnected() {
    // TODO(alex): implement logic onDeviceDisconnected if needed
  }

  @override
  void onDeviceReconnected() {
    // TODO(alex): implement logic onDeviceReconnected if needed
  }
}