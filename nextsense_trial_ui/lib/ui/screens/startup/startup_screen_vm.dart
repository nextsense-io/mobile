import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class StartupScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('StartupScreenViewModel');
  final DataManager _dataManager = getIt<DataManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final Navigation _navigation = getIt<Navigation>();

  StartupScreenViewModel();

  void init() async {
    setBusy(true);
    if (!_dataManager.userDataLoaded) {
      bool success = false;
      try {
        success = await _dataManager.loadUserData();
      } catch (e, stacktrace) {
        _logger.log(Level.SEVERE,
            'load user data failed with exception: '
                '${e.toString()}, ${stacktrace.toString()}');
      }
      if (!success) {
        _logger.log(
            Level.SEVERE, 'Failed to load user data. Fallback to sign in');
        logout();
        return;
      }
      setBusy(false);
    }

    // Navigate to the device preparation screen by default, but in case we
    // already have paired device before, then navigate directly to dashboard
    // Note: we have same logic in sign in screen
    String screen = PrepareDeviceScreen.id;
    if (_deviceManager.hadPairedDevice) {
      await _deviceManager.connectToLastPairedDevice();
      screen = DashboardScreen.id;
    }

    _navigation.navigateWithConnectionChecking(screen, replace: true);
  }

  void logout() {
    _authManager.signOut();
    _navigation.signOut();
  }
}