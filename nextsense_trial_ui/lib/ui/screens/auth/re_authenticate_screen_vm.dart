import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class ReAuthenticateScreenViewModel extends ViewModel {

  AuthManager _authManager = getIt<AuthManager>();

  String? password;

  Future<bool> reAuthenticate() async {
    if (password == null || password!.isEmpty) {
      return false;
    }
    setBusy(true);
    notifyListeners();
    bool auth = false;
    try {
      AuthenticationResult result = await _authManager.reAuthenticate(password!);
      if (result == AuthenticationResult.success) {
        auth = true;
      } else {
        setError('Invalid password, please try again.');
      }
    } catch (e) {
      setError('Could validate your password, make sure you have an active internet connection and '
          'try again.');
    }
    setBusy(false);
    notifyListeners();
    return auth;
  }
}