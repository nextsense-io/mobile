import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SetPasswordScreenViewModel extends ViewModel {

  final AuthManager authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SetPasswordScreenViewModel');

  String password = "";
  String passwordConfirmation = "";

  int get minimumPasswordLength => AuthManager.minimumPasswordLength;

  Future<bool> changePassword() async {
    if (password.isEmpty) {
      return false;
    }
    if (password.length < minimumPasswordLength) {
      setError('Password should be at least ${minimumPasswordLength} characters long');
      notifyListeners();
      return false;
    }
    if (password.compareTo(passwordConfirmation) != 0) {
      setError('Passwords do not match.');
      notifyListeners();
      return false;
    }
    setBusy(true);
    notifyListeners();
    bool passwordChanged = false;
    try {
      passwordChanged = await authManager.changePassword(password);
    } catch (e) {
      setBusy(false);
      notifyListeners();
      return false;
    }
    _logger.log(Level.INFO, 'Password change result: ${passwordChanged}');
    setBusy(false);
    notifyListeners();
    return passwordChanged;
  }
}