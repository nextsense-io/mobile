import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';

class GoogleAuthManager {
  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final GoogleSignIn _googleSignIn;
  late FirebaseAuth _firebaseAuth;
  final _logger = CustomLogPrinter('GoogleAuthManager');
  String? _authUid;

  GoogleSignInAccount? _googleSignInAccount;

  GoogleAuthManager() : _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],) {
    _firebaseAuth = FirebaseAuth.instanceFor(app: _firebaseApp);
  }

  String get email => _googleSignInAccount?.email ?? "";
  String get authUid => _authUid ?? "";

  Future<AuthenticationResult> handleSignIn() async {
    _logger.log(Level.INFO, 'Starting Google sign-in.');
    GoogleSignInAccount? googleSignInAccount;
    try {
      googleSignInAccount = await _googleSignIn.signIn();
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.SEVERE, "Error when trying to sign in: $e");
      return AuthenticationResult.error;
    }
    if (googleSignInAccount == null) {
      _logger.log(Level.WARNING, 'Could not authenticate with Google.');
      return AuthenticationResult.error;
    }
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    AuthCredential authCredential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    _googleSignInAccount = _googleSignIn.currentUser;

    // Authenticate in Firebase using the authentication credentials that were
    // obtained from Google Auth.
    try {
      final UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(authCredential);
      if (userCredential.user == null || userCredential.user!.isAnonymous) {
        _logger.log(Level.SEVERE, "No user returned from Google Auth.");
        return AuthenticationResult.error;
      }
      _authUid = userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.SEVERE, "Error when trying to authenticate with Google Auth: $e");
      return AuthenticationResult.error;
    }
    return AuthenticationResult.success;
  }

  Future<void> handleSignOut() async {
    _googleSignInAccount = null;
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}