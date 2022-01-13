import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/user_password_auth_manager.dart';
import 'package:uuid/uuid.dart';

enum UserCodeValidationResult {
  valid,
  invalid,
  password_not_set
}

class AuthManager {
  static const minimumPasswordLength = 8;

  final FirestoreManager _firestoreManager =
      GetIt.instance.get<FirestoreManager>();
  final Uuid _uuid = Uuid();
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // final GoogleAuthManager _googleAuthManager = GoogleAuthManager();

  String? _userCode;
  User? _user;
  bool _authorized = false;

  AuthManager() {}

  Future<UserCodeValidationResult> validateUserCode(String code) async {
    FirebaseEntity userEntity =
        await _firestoreManager.queryEntity([Table.users], [code]);
    if (!userEntity.getDocumentSnapshot().exists) {
      return UserCodeValidationResult.invalid;
    }
    _user = User(userEntity);
    _userCode = code;
    if (_user!.getValue(UserKey.password) == null) {
      return UserCodeValidationResult.password_not_set;
    }
    return UserCodeValidationResult.valid;
  }

  Future<void> setPassword(String password) async {
    if (_user == null) {
      throw('Cannot set password on non-existent user.');
    }
    _user!.setValue(UserKey.password,
        UserPasswordAuthManager.generatePasswordHash(password));
    _firestoreManager.persistEntity(_user!);
  }

  Future<bool> signIn(String password) async {
    _authorized =  UserPasswordAuthManager.isPasswordValid(
        password, _user!.getValue(UserKey.password));
    if (_authorized && _user!.getValue(UserKey.bt_key) == null) {
      _user!.setValue(UserKey.bt_key, _uuid.v4());
      _firestoreManager.persistEntity(_user!);
    }
    return _authorized;
  }

  Future<void> signOut() async {
    _authorized = false;
  }

  bool isAuthorized() {
    return _authorized;
  }

  String? getUserCode() {
    return _userCode;
  }

  User? getUserEntity() {
    return _user;
  }

  // Future<SignInResult> signIn() async {
  //   // TODO(eric): Allow authentication using different methods, not only
  //   //             Google.
  //   AuthCredential authCredential = await _googleAuthManager.handleSignIn();
  //   try {
  //     final UserCredential userCredential =
  //         await _firebaseAuth.signInWithCredential(authCredential);
  //     _user = userCredential.user;
  //     if (_user!.isAnonymous) {
  //       return SignInResult.failed;
  //     }
  //     _authorized = true;
  //     return SignInResult.success;
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'account-exists-with-different-credential') {
  //       return SignInResult.failed;
  //     }
  //     else if (e.code == 'invalid-credential') {
  //       return SignInResult.failed;
  //     }
  //   } catch (e) {
  //     return SignInResult.failed;
  //   }
  //   return SignInResult.failed;
  // }

  // Future<void> signOut() async {
  //   // TODO(eric): Allow sign out using different methods, not only Google.
  //   _authorized = false;
  //   await _googleAuthManager.handleSignOut();
  //   await _firebaseAuth.signOut();
  // }
}