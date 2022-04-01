import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/api.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:uuid/uuid.dart';

enum AuthenticationResult {
  success,
  invalid_username_or_password,
  user_fetch_failed,
  connection_error,
  error
}

class AuthManager {
  static const minimumPasswordLength = 8;

  final _logger = CustomLogPrinter('AuthManager');
  final _firestoreManager = getIt<FirestoreManager>();
  final _nextsenseApi = getIt<NextsenseApi>();
  final _preferences = getIt<Preferences>();

  final Uuid _uuid = Uuid();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _userCode;
  User? _user;
  bool get isAuthorized => _user != null;

  User? get user => _user;

  AuthManager() {}

  String? getUserCode() {
    return _userCode;
  }

  Future<AuthenticationResult> signIn(String username, String password) async {

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
    try {
      await _firebaseAuth.signInWithCustomToken(resp.data['token']);
    } on FirebaseAuthException catch (e) {
      _logger.log(Level.SEVERE, e);
      return AuthenticationResult.error;
    }

    _user = await fetchUserFromFirestore(username);

    if (_user == null) {
      return AuthenticationResult.user_fetch_failed;
    }

    _userCode = username;

    // Persist bt_key
    if (_user!.getValue(UserKey.bt_key) == null) {
      _user!
        ..setValue(UserKey.bt_key, _uuid.v4())
        ..save();
    }

    return AuthenticationResult.success;
  }

  Future<User?> fetchUserFromFirestore(String code) async {
    FirebaseEntity userEntity;
    try {
      userEntity = await _firestoreManager.queryEntity([Table.users], [code]);
    } catch(e) {
      return null;
    }
    if (!userEntity.getDocumentSnapshot().exists) {
      return null;
    }

    return User(userEntity);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _userCode = null;
    _user = null;
  }

}