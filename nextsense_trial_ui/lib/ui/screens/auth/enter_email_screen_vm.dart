import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class EnterEmailScreenViewModel extends ViewModel {

  AuthManager _authManager = getIt<AuthManager>();

  String? email;

  Future<bool> setEmailInAuthManager() async {
    if (email == null || email!.isEmpty) {
      return false;
    }
    _authManager.setEmail(email!);
    // TODO(eric): Validate email in database.
    return true;
  }
}