import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class RequestPasswordResetScreenViewModel extends ViewModel {

  AuthManager _authManager = getIt<AuthManager>();

  String? email;

  Future<bool> sendPasswordResetEmail() async {
    if (email == null || email!.isEmpty) {
      return false;
    }
    setBusy(true);
    notifyListeners();
    bool result = false;
    try {
      result = await _authManager.requestPasswordResetEmail(email!);
    } catch (e) {
      setError('Could request en email for your password change, please make sure you have an '
          'active internet connection and try again.');
    }
    if (result == false) {
      setError('Please enter a valid email address.');
    }
    setBusy(false);
    notifyListeners();
    return result;
  }


}