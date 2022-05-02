import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/google_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/auth/nextsense_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
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
  final _preferences = getIt<Preferences>();
  final _firestoreManager = getIt<FirestoreManager>();
  final _flavor = getIt<Flavor>();
  final Uuid _uuid = Uuid();

  NextSenseAuthManager? _nextSenseAuthManager;
  GoogleAuthManager? _googleAuthManager;
  String? _userCode;
  User? _user;
  AuthMethod? _signedInAuthMethod;

  bool get isAuthorized => _user != null;
  User? get user => _user;
  String? get userCode => _userCode;

  AuthManager() {
    for (AuthMethod authMethod in _flavor.authMethods) {
      switch (authMethod) {
        case AuthMethod.user_code:
          _nextSenseAuthManager = NextSenseAuthManager();
          break;
        case AuthMethod.google_auth:
          _googleAuthManager = GoogleAuthManager();
          break;
      }
    }
  }

  Future<AuthenticationResult> signInNextSense(
      String username, String password) async {
    AuthenticationResult authResult =
        await _nextSenseAuthManager!.handleSignIn(username, password);
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    authResult = await _signIn(username);
    if (authResult == AuthenticationResult.success) {
      _signedInAuthMethod = AuthMethod.user_code;
    }
    return authResult;
  }

  Future<AuthenticationResult> signInGoogle() async {
    AuthenticationResult authResult = await _googleAuthManager!.handleSignIn();
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    _logger.log(Level.INFO, 'Authenticated with Google with success');
    return await _signIn(_googleAuthManager!.email);
  }

  Future<AuthenticationResult> _signIn(String username) async {
    _logger.log(Level.INFO, 'Starting NextSense user check for $username');
    _user = await fetchUserFromFirestore(username);

    if (_user == null) {
      await signOut();
      return AuthenticationResult.user_fetch_failed;
    }

    if (_user!.getUserType() != _flavor.userType) {
      await signOut();
      return AuthenticationResult.invalid_username_or_password;
    }

    _userCode = username;

    // Persist bt_key
    if (_user!.getValue(UserKey.bt_key) == null) {
      _user!.setValue(UserKey.bt_key, _uuid.v4());
    }

    // Persist fcm token
    String? fcmToken = _preferences.getString(PreferenceKey.fcmToken);
    if (fcmToken != null) {
      _user!.setFcmToken(fcmToken);
    }

    // Save timezone
    // TODO(alex): handle timezone change in broadcast receiver
    _user!.updateTimezone();

    user!.save();

    _logger.log(Level.INFO, "SignIn successful");
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
    switch (_signedInAuthMethod) {
      case AuthMethod.user_code:
        await _nextSenseAuthManager!.handleSignOut();
        break;
      case AuthMethod.google_auth:
        await _googleAuthManager!.handleSignOut();
        break;
      default:
        // Nothing to do.
    }
    _userCode = null;
    _user = null;
    _signedInAuthMethod = null;
  }
}