import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/email_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/auth/google_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/auth/nextsense_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:uuid/uuid.dart';

enum AuthenticationResult {
  success,
  invalid_user_setup, // Invalid user configuration in Firestore
  invalid_username_or_password,
  user_fetch_failed, // Failed to load user entity
  connection_error,
  error // Some other errors
}

class AuthManager {
  static const minimumPasswordLength = 8;
  static const _emailLinkParam = 'email';

  final _logger = CustomLogPrinter('AuthManager');
  final _preferences = getIt<Preferences>();
  final _firestoreManager = getIt<FirestoreManager>();
  final _firebaseAuth = FirebaseAuth.instance;
  final _flavor = getIt<Flavor>();

  final Uuid _uuid = Uuid();

  NextSenseAuthManager? _nextSenseAuthManager;
  GoogleAuthManager? _googleAuthManager;
  EmailAuthManager? _emailAuthManager;
  String? _userCode;
  User? _user;
  AuthMethod? _signedInAuthMethod;

  // User has logged in with Firebase account.
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  // User is fetched from Firestore and allowed to use his account.
  bool get isAuthorized => _user != null;

  bool get isTempPassword => _user?.isTempPassword() ?? false;

  User? get user => _user;
  String? get userCode => _userCode;

  AuthManager() {
    for (AuthMethod authMethod in _flavor.authMethods) {
      switch (authMethod) {
        case AuthMethod.email_password:
          _emailAuthManager = EmailAuthManager();
          _signedInAuthMethod = AuthMethod.email_password;
          break;
        case AuthMethod.user_code:
          _nextSenseAuthManager = NextSenseAuthManager();
          _signedInAuthMethod = AuthMethod.user_code;
          break;
        case AuthMethod.google_auth:
          _googleAuthManager = GoogleAuthManager();
          _signedInAuthMethod = AuthMethod.google_auth;
          break;
      }
    }
  }

  Future<AuthenticationResult> signInNextSense(String username, String password) async {
    AuthenticationResult authResult = await _nextSenseAuthManager!.handleSignIn(username, password);
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    authResult = await _signIn(username: username, authUid: username);
    return authResult;
  }

  Future<AuthenticationResult> signInGoogle() async {
    AuthenticationResult authResult = await _googleAuthManager!.handleSignIn();
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    _logger.log(Level.INFO, 'Authenticated with Google with success');
    return await _signIn(username: _googleAuthManager!.email, authUid: _googleAuthManager!.authUid);
  }

  Future<AuthenticationResult> signInEmailLink(String emailLink) async {
    Uri uri = Uri.parse(emailLink);
    String? email = uri.queryParameters[_emailLinkParam];
    if (email == null) {
      _logger.log(Level.WARNING,
          "Received an email link with no $_emailLinkParam parameter, cannot process it.");
      return AuthenticationResult.error;
    }
    AuthenticationResult authResult = await _emailAuthManager!.signInWithLink(email, emailLink);
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    authResult = await _signIn(username: email, authUid: _emailAuthManager!.authUid);
    return authResult;
  }

  Future<AuthenticationResult> signInEmailPassword(String username, String password) async {
    AuthenticationResult authResult = await _emailAuthManager!.handleSignIn(username, password);
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    authResult = await _signIn(username: username, authUid: _emailAuthManager!.authUid);
    return authResult;
  }

  // Might not need this?
  Future<AuthenticationResult> signUpEmailPassword(String email, String password) async {
    AuthenticationResult result = await _signIn(username: email, authUid: "");
    if (result == AuthenticationResult.success) {
      result = await _emailAuthManager!.handleSignUp(email, password);
    }
    return result;
  }

  Future<AuthenticationResult> reAuthenticate(String password) async {
    switch (_signedInAuthMethod) {
      case AuthMethod.email_password:
        return await _emailAuthManager!.reAuthenticate(password);
      default:
        return AuthenticationResult.error;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    switch (_signedInAuthMethod) {
      case AuthMethod.email_password:
        bool passwordChanged = await _emailAuthManager!.changePassword(newPassword);
        if (passwordChanged) {
          _user!.setTempPassword(false);
          bool saved = await _user!.save();
          return saved;
        }
        return false;
      case AuthMethod.user_code:
    return await _nextSenseAuthManager!.changePassword(userCode!, newPassword);
      default:
        return false;
    }
  }

  Future<AuthenticationResult> _signIn({required String username, String? authUid}) async {
    _logger.log(Level.INFO, 'Starting NextSense user check for $username');
    _user = await loadUser(username: username, authUid: authUid);

    if (_user == null) {
      await signOut();
      return AuthenticationResult.user_fetch_failed;
    }

    // Check user type match current flavor of app
    // 'researcher' user can only use 'researcher' flavored app
    // 'subject' user can only use 'subject' flavored app
    if (_user!.userType != _flavor.userType) {
      await signOut();
      return AuthenticationResult.invalid_user_setup;
    }
    return AuthenticationResult.success;
  }

  // Load user from Firestore and update some data
  Future<User?> loadUser({required String username, String? authUid}) async {
    final User? user = await fetchUserFromFirestore(username);

    if (user == null) {
      _logger.log(Level.WARNING, 'Failed to fetch user from Firestore');
      return null;
    }

    // Persist bt_key
    if (user.getValue(UserKey.bt_key) == null) {
      user.setValue(UserKey.bt_key, _uuid.v4());
    }

    // Persist UID on first login.
    if (user.getValue(UserKey.auth_uid) == null) {
      if (authUid == null) {
        _logger.log(Level.SEVERE, 'No auth UID, cannot login.');
        return null;
      }
      user.setValue(UserKey.auth_uid, authUid);
    }

    // Persist fcm token
    String? fcmToken = _preferences.getString(PreferenceKey.fcmToken);
    if (fcmToken != null) {
      user.setFcmToken(fcmToken);
    }

    // Save timezone
    // TODO(alex): handle timezone change in broadcast receiver
    await user.updateTimezone();
    await user.save();
    _userCode = username;

    return user;
  }

  Future<User?> fetchUserFromFirestore(String code) async {
    FirebaseEntity? userEntity = await _firestoreManager.queryEntity([Table.users], [code]);
    if (userEntity == null || !userEntity.getDocumentSnapshot().exists) {
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
  }

  // Make sure user data is loaded from Firestore before we are doing any authorized operations.
  //
  // Returns true if user is successfully initialized, otherwise returns false and further actions
  // must be taken.
  Future<bool> ensureUserLoaded() async {
    _logger.log(Level.INFO, 'ensure user loaded');
    if (_user != null) {
      // User already initialized
      return true;
    }

    // Try to get user from username stored in firebase auth instance
    if (_firebaseAuth.currentUser != null) {
      String username;
      String authUid = "";
      switch (_signedInAuthMethod) {
        case AuthMethod.user_code:
          username = _firebaseAuth.currentUser!.uid;
          authUid = username;
          break;
        case AuthMethod.google_auth:
          username = _firebaseAuth.currentUser!.email!;
          authUid = _googleAuthManager!.authUid;
          break;
        case AuthMethod.email_password:
          username = _firebaseAuth.currentUser!.email!;
          authUid = _emailAuthManager!.authUid;
          break;
        default:
          _logger.log(Level.WARNING, 'Unknown auth method.');
          return false;
      }
      _user = await loadUser(username: username, authUid: authUid);
      if (_user != null) {
        return true;
      }
    }

    _logger.log(Level.WARNING, 'Failed to initialize user');
    return false;
  }
}