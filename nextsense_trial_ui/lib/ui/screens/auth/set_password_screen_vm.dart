import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SetPasswordScreenViewModel extends ViewModel {

  final AuthManager authManager = getIt<AuthManager>();

  int get minimumPasswordLength => AuthManager.minimumPasswordLength;

  Future<bool> changePassword(String newPassword) async {
    setBusy(true);
    bool passwordChanged = await authManager.changePassword(newPassword);
    setBusy(false);
    return passwordChanged;
  }
}