import 'package:flutter_common/managers/auth/password_change_result.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class SetPasswordScreenViewModel extends ViewModel {

  final AuthManager authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SetPasswordScreenViewModel');

  String password = "";
  String passwordConfirmation = "";

  int get minimumPasswordLength => AuthManager.minimumPasswordLength;

  Future<PasswordChangeResult> changePassword() async {
    if (password.isEmpty) {
      return PasswordChangeResult.invalid_password;
    }
    if (password.length < minimumPasswordLength) {
      setError('Password should be at least $minimumPasswordLength characters long');
      notifyListeners();
      return PasswordChangeResult.error;
    }
    if (password.compareTo(passwordConfirmation) != 0) {
      setError('Passwords do not match.');
      notifyListeners();
      return PasswordChangeResult.error;
    }
    setBusy(true);
    notifyListeners();
    PasswordChangeResult? result;
    try {
      result = await authManager.changePassword(password);
    } catch (e) {
      setBusy(false);
      notifyListeners();
      return PasswordChangeResult.error;
    }
    _logger.log(Level.INFO, 'Password change result: $result');
    setBusy(false);
    notifyListeners();
    return result;
  }
}