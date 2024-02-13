import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/managers/health_connect_manager.dart';

class NoSleepDataViewModel extends ViewModel {
  final _healthConnectManager = getIt<HealthConnectManager>();

  openSamsungHealthApp() {
    _healthConnectManager.openSamsungHealthApp();
  }

  openFitbitApp() {
    _healthConnectManager.openFitbitApp();
  }

  openGoogleFitApp() {
    _healthConnectManager.openGoogleFitApp();
  }
}