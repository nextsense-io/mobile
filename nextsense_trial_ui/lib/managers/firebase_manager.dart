import 'package:firebase_core/firebase_core.dart';

class FirebaseManager {
  FirebaseApp? _firebaseApp;

  Future initializeFirebase() async {
    _firebaseApp = await Firebase.initializeApp();
  }

  FirebaseApp getFirebaseApp() {
    if (_firebaseApp == null) {
      throw 'Firebase not initialized!';
    }
    return _firebaseApp!;
  }
}
