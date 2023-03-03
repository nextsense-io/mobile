import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseManager {
  FirebaseApp? _firebaseApp;

  Future initializeFirebase() async {
    _firebaseApp = await Firebase.initializeApp();
    if (kReleaseMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    }
  }

  FirebaseApp getFirebaseApp() {
    if (_firebaseApp == null) {
      throw 'Firebase not initialized!';
    }
    return _firebaseApp!;
  }
}
