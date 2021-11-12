import 'package:firebase_core/firebase_core.dart';

class FirebaseManager {

  static Future<FirebaseApp> initializeFirebase() async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    return firebaseApp;
  }
}
