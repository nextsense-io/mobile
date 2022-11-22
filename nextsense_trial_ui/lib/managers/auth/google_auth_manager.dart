import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

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
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
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
          return AuthenticationResult.error;
        }
        _authUid = userCredential.user!.uid;
      } on FirebaseAuthException catch (e) {
        _logger.log(Level.SEVERE, e);
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