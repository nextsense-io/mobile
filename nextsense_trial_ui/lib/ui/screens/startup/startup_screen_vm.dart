import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/prepare_device_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/sign_in_screen.dart';
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

  @override
  void init() async {
    setBusy(true);
    super.init();
    // Make sure an internet connection is active before starting. If don't have one, show the login
    // which will display an error.
    if (getIt<ConnectivityManager>().isNone) {
      Future.delayed(Duration(seconds: 0)).then(
              (value) => _navigation.navigateTo(SignInScreen.id, replace: true));
      return;
    }
    if (!_dataManager.userLoaded) {
      bool success = false;
      try {
        success = await _dataManager.loadUser();
      } catch (e, stacktrace) {
        _logger.log(Level.SEVERE,
            'load user failed with exception: ${e.toString()}, ${stacktrace.toString()}');
      }
      if (!success) {
        setBusy(false);
        _logger.log(Level.SEVERE, 'Failed to load user. Fallback to sign in');
        logout();
        return;
      }
    }

    _logger.log(Level.INFO, 'Checking if temporary password.');
    if (_authManager.isTempPassword) {
      setBusy(false);
      // If the user got a temp password, make him sign in again and then change it.
      _logger.log(Level.INFO, 'Temporary password. Navigating to password change screen.');
      _navigation.navigateTo(SignInScreen.id, replace: true);
      return;
    }

    if (!_dataManager.userStudyDataLoaded) {
      bool success = false;
      try {
        success = await _dataManager.loadUserStudyData();
      } catch (e, stacktrace) {
        _logger.log(Level.SEVERE, 'load user data failed with exception: ${e.toString()}, '
            '${stacktrace.toString()}');
      }
      if (!success) {
        setBusy(false);
        _logger.log(Level.SEVERE, 'Failed to load user. Fallback to sign in');
        logout();
        return;
      }
    }

    // Navigate to the device preparation screen by default, but in case we already have paired
    // device before, then navigate directly to dashboard. Note: we have same logic in sign in
    // screen.
    String screen = PrepareDeviceScreen.id;
    if (_deviceManager.hadPairedDevice) {
      await _deviceManager.connectToLastPairedDevice();
      screen = DashboardScreen.id;
    }

    if (_navigation.hasInitialIntent()) {
      _navigation.navigateWithConnectionChecking(screen, replace: true);
      _navigation.navigateToInitialIntent();
      setBusy(false);
      return;
    }

    await _navigation.navigateWithConnectionChecking(screen, replace: true).then(
            (value) => _navigation.navigateToInitialIntent());

    setBusy(false);
  }

  void logout() {
    _authManager.signOut();
    _navigation.signOut();
  }
}