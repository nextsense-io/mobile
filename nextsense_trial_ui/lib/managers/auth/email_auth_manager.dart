import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/managers/nextsense_api.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:email_validator/email_validator.dart';

class EmailAuthManager {
  static const int maxEmailLength = 50;
  static const int maxPasswordLength = 20;
  static const String _requireRecentLoginFirebaseError = 'requires-recent-login';
  static const String _invalidEmailFirebaseError = 'invalid-email';
  static const String _wrongPasswordFirebaseError = 'wrong-password';
  static const String _userNotFoundFirebaseError = 'user-not-found';
  static const String _expiredActionCodeFirebaseError = 'expired-action-code';

  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final _nextsenseApi = getIt<NextsenseApi>();
  final _logger = CustomLogPrinter('EmailAuthManager');
  late FirebaseAuth _firebaseAuth;

  GoogleSignInAccount? _googleSignInAccount;
  String? _authUid;

  EmailAuthManager() {
    _firebaseAuth = FirebaseAuth.instanceFor(app: _firebaseApp);
  }

  String get email => _googleSignInAccount?.email ?? "";
  String get authUid => _authUid ?? "";

  bool _isInvalidCredentialError(FirebaseException e) {
    return e.code == _invalidEmailFirebaseError || e.code == _wrongPasswordFirebaseError ||
        e.code == _userNotFoundFirebaseError;
  }

  // Currently unused. Delete once feature is complete.
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
    if (!EmailValidator.validate(email)) {
      return AuthenticationResult.invalid_username_or_password;
    }
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user!.isAnonymous) {
        return AuthenticationResult.error;
      }
      _authUid = userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Could not authenticate with Email in Firebase. ${e.message}');
      if (_isInvalidCredentialError(e)) {
        return AuthenticationResult.invalid_username_or_password;
      }
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<bool> sendSignUpLinkEmail(String email) async {
    if (!EmailValidator.validate(email)) {
      return false;
    }
    ApiResponse resp = await _nextsenseApi.sendSignInEmail(
        email: email, emailType: SignInEmailType.signUp);
    return !resp.isError;
  }

  Future<bool> sendResetPasswordEmail(String email) async {
    if (!EmailValidator.validate(email)) {
      return false;
    }
    ApiResponse resp = await _nextsenseApi.sendSignInEmail(
        email: email, emailType: SignInEmailType.resetPassword);
    return !resp.isError;
  }

  Future<AuthenticationResult> signInWithLink(String email, String emailLink) async {
    if (!EmailValidator.validate(email)) {
      return AuthenticationResult.invalid_username_or_password;
    }
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailLink(
          email: email, emailLink: emailLink);
      if (userCredential.user!.isAnonymous) {
        return AuthenticationResult.error;
      }
      _authUid = userCredential.user!.uid;
      _logger.log(Level.INFO, 'Successfully signed in with email link.');
    } on FirebaseException catch (e) {
      _logger.log(Level.WARNING,
          'Failed to sign in with email link. Error: ${e.message}');
      if (e.code == _expiredActionCodeFirebaseError) {
        return AuthenticationResult.expired_link;
      }
      return AuthenticationResult.error;
    } catch (error) {
      _logger.log(Level.WARNING,
          'Error when trying to sign in with email link. Error: ${error.toString()}');
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<PasswordChangeResult> changePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Failed to change password. Error: ${e.toString()}');
      if (e.code == _requireRecentLoginFirebaseError) {
        return PasswordChangeResult.need_reauthentication;
      }
      return PasswordChangeResult.error;
    } on Exception catch (e) {
      _logger.log(Level.WARNING,
          'Error when trying to change the password. Error: ${e.toString()}');
      return PasswordChangeResult.connection_error;
    }
    return PasswordChangeResult.success;
  }

  Future<AuthenticationResult> reAuthenticate(String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
          email: _firebaseAuth.currentUser!.email!, password: password);
      await _firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.WARNING, 'Could not re-authenticate with Email in Firebase. ${e.message}');
      if (_isInvalidCredentialError(e)) {
        return AuthenticationResult.invalid_username_or_password;
      }
      return AuthenticationResult.error;
    } on Exception catch (e) {
      _logger.log(Level.WARNING, 'Error when trying to re-authenticate with Firebase. $e');
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<void> handleSignOut() async {
    await _firebaseAuth.signOut();
  }
}