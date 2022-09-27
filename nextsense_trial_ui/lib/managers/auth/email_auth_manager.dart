import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class EmailAuthManager {
  static const String _requireRecentLoginFirebaseError = 'requires-recent-login';

  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  late FirebaseAuth _firebaseAuth;
  final _logger = CustomLogPrinter('EmailAuthManager');

  GoogleSignInAccount? _googleSignInAccount;

  EmailAuthManager() {
    _firebaseAuth = FirebaseAuth.instanceFor(app: _firebaseApp);
  }

  String get email => _googleSignInAccount?.email ?? "";

  Future<AuthenticationResult> handleSignUp(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthenticationResult.success;
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Could not signup with Email in Firebase. ${e.message}');
      return AuthenticationResult.error;
    }
  }

  Future<AuthenticationResult> handleSignIn(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user!.isAnonymous) {
        return AuthenticationResult.error;
      }
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Could not authenticate with Email in Firebase. ${e.message}');
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == _requireRecentLoginFirebaseError) {
        // Navigate to reAuthenticate page then try again.
        await _firebaseAuth.currentUser!.updatePassword(newPassword);
      }
    }
    return true;
  }

  Future<AuthenticationResult> reAuthenticate(String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: _firebaseAuth.currentUser!.email!, password: password);
      await _firebaseAuth.currentUser!.reauthenticateWithCredential(userCredential.credential!);
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Could not re-authenticate with Email in Firebase. ${e.message}');
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<void> handleSignOut() async {
    await _firebaseAuth.signOut();
  }
}