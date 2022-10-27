import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/nextsense_api.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class NextSenseAuthManager {

  final _nextsenseApi = getIt<NextsenseApi>();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _logger = CustomLogPrinter('NextSenseAuthManager');

  Future<AuthenticationResult> handleSignIn(String username, String password) async {
    ApiResponse resp = await _nextsenseApi.auth(username, password);

    if (resp.isError) {
      if (resp.isConnectionError)
        return AuthenticationResult.connection_error;

      if (resp.error == 'INVALID_USERNAME_OR_PASSWORD')
        return AuthenticationResult.invalid_username_or_password;

      //TODO(alex): handle other errors?
      return AuthenticationResult.error;
    }

    // Authenticate in Firebase using the token that was obtained
    // from the backend
    String token = resp.data['token'];
    try {
      await _firebaseAuth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.SEVERE, e);
      return AuthenticationResult.error;
    }

    return AuthenticationResult.success;
  }

  Future<PasswordChangeResult> changePassword(
      {required String username, required String newPassword}) async {
    ApiResponse resp = await _nextsenseApi.changePassword(
        await _firebaseAuth.currentUser!.getIdToken(), username, newPassword);
    if (resp.isError) {
      return PasswordChangeResult.error;
    }
    return PasswordChangeResult.success;
  }

  Future<void> handleSignOut() async {
    await _firebaseAuth.signOut();
  }
}