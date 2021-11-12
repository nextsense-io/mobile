import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthManager {
  final GoogleSignIn _googleSignIn;

  GoogleAuthManager() : _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],) {}

  Future<AuthCredential> handleSignIn() async {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        return GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
      }
      return Future.error("Could not authenticate with Google.");
  }

  Future<void> handleSignOut() async {
    await _googleSignIn.signOut();
  }
}