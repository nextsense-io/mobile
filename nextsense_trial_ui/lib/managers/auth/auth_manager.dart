import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/auth/email_auth_manager.dart';
import 'package:flutter_common/managers/auth/google_auth_manager.dart';
import 'package:flutter_common/managers/auth/password_change_result.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/nextsense_auth_manager.dart';
import 'package:nextsense_trial_ui/managers/trial_ui_firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:uuid/uuid.dart';

class AuthManager {
  static const minimumPasswordLength = 8;

  final _logger = CustomLogPrinter('AuthManager');
  final _preferences = getIt<Preferences>();
  final _firestoreManager = getIt<TrialUiFirestoreManager>();
  final _firebaseAuth = FirebaseAuth.instance;
  final _flavor = getIt<Flavor>();

  final Uuid _uuid = Uuid();

  NextSenseAuthManager? _nextSenseAuthManager;
  GoogleAuthManager? _googleAuthManager;
  EmailAuthManager? _emailAuthManager;
  String? _email;
  String? _username;
  User? _user;
  AuthMethod? _signedInAuthMethod;

  // User has logged in with Firebase account.
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  // User is fetched from Firestore and allowed to use his account.
  bool get isAuthorized => _user != null;

  bool get isTempPassword => _user?.isTempPassword() ?? false;

  User? get user => _user;
  String? get username => _username;
  String? get email => _email;

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

  setEmail(String email) {
    _email = email;
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

  Future<AuthenticationResult> signInEmailLink(String emailLink, String email) async {
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

  Future<PasswordChangeResult> changePassword(String newPassword) async {
    switch (_signedInAuthMethod) {
      case AuthMethod.email_password:
        PasswordChangeResult result = await _emailAuthManager!.changePassword(newPassword);
        if (result == PasswordChangeResult.success) {
          _user!.setTempPassword(false);
          await _user!.save();
          return result;
        }
        return result;
      case AuthMethod.user_code:
    return await _nextSenseAuthManager!.changePassword(
        username: username!, newPassword: newPassword);
      default:
        return PasswordChangeResult.error;
    }
  }

  Future<bool> requestPasswordResetEmail(String email) async {
    switch (_signedInAuthMethod) {
      case AuthMethod.email_password:
        if (!EmailValidator.validate(email)) {
          _logger.log(Level.WARNING, "Invalid email: " + email);
          return false;
        }
        _email = email;
        return await _emailAuthManager!.sendResetPasswordEmail(email);
      default:
        _logger.log(Level.WARNING,
            'Cannot send a password reset email for $_signedInAuthMethod users.');
        return false;
    }
  }

  Future<bool> requestSignUpEmail(String email) async {
    switch (_signedInAuthMethod) {
      case AuthMethod.email_password:
        User? user = await _loadUser(authUid: email);
        user?.setTempPassword(true);
        user?.save();
        return await _emailAuthManager!.sendSignUpLinkEmail(email);
      default:
        _logger.log(Level.WARNING,
            'Cannot send a signup email for $_signedInAuthMethod users.');
        return false;
    }
  }


  String? getLastPairedMacAddress() {
    return user?.getLastPairedDeviceMacAddress();
  }

  // Make sure the user data is loaded from Firestore before doing any authorized operations.
  //
  // Returns true if the user is successfully initialized, otherwise returns false.
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
      _user = await _loadUser(authUid: authUid);
      if (_user != null) {
        _username = username;
        await _updateUserDetails(user: _user!);
        return true;
      }
    }
    _logger.log(Level.WARNING, 'Failed to initialize user');
    return false;
  }

  Future<void> signOut() async {
    switch (_signedInAuthMethod) {
      case AuthMethod.user_code:
        await _nextSenseAuthManager!.handleSignOut();
        break;
      case AuthMethod.google_auth:
        await _googleAuthManager!.handleSignOut();
        break;
      case AuthMethod.email_password:
        await _emailAuthManager!.handleSignOut();
        break;
      default:
      // Nothing to do.
    }
    _username = null;
    _user = null;
    _email = null;
  }

  Future<AuthenticationResult> _signIn({required String username, required String authUid}) async {
    _logger.log(Level.INFO, 'Starting NextSense user check.');
    _user = await _loadUser(authUid: authUid);

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
    _updateUserDetails(user: _user!);
    _username = username;
    _firestoreManager.setUserId(_user!.id);
    return AuthenticationResult.success;
  }

  Future _updateUserDetails({required User user}) async {
    // Persist bt_key
    if (user.getValue(UserKey.bt_key) == null) {
      user.setValue(UserKey.bt_key, _uuid.v4());
    }

    // Persist fcm token
    String? fcmToken = _preferences.getString(PreferenceKey.fcmToken);
    if (fcmToken != null) {
      user.setFcmToken(fcmToken);
    }

    // Save timezone
    // TODO(alex): handle timezone change in broadcast receiver
    await user.updateTimezone();
    user.setLastLogin(DateTime.now());
    await user.save();
  }

  // Load user from Firestore and update some data
  Future<User?> _loadUser({required String authUid}) async {
    final User? user = await _fetchUserFromFirestore(authUid);

    if (user == null) {
      _logger.log(Level.WARNING, 'Failed to fetch user from Firestore.');
      return null;
    }
    return user;
  }

  Future<User?> _fetchUserFromFirestore(String authUid) async {
    FirebaseEntity? userEntity = await _firestoreManager.queryEntity([Table.users], [authUid]);
    if (userEntity == null || !userEntity.getDocumentSnapshot().exists) {
      return null;
    }
    return User(userEntity);
  }
}