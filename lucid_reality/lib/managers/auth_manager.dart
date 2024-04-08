import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/auth/email_auth_manager.dart';
import 'package:flutter_common/managers/auth/google_auth_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/user_entity.dart';
import 'package:lucid_reality/managers/connectivity_manager.dart';
import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/utils/connectivity_extension.dart';

class AuthManager {
  static const minimumPasswordLength = 8;

  final _logger = CustomLogPrinter('AuthManager');
  final _firebaseAuth = FirebaseAuth.instance;
  final firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();
  final ConnectivityManager _connectivityManager = getIt<ConnectivityManager>();

  GoogleAuthManager? _googleAuthManager;
  EmailAuthManager? _emailAuthManager;
  String? _email;
  String? _username;
  UserEntity? _user;
  AuthMethod? _signedInAuthMethod;

  // User has logged in with Firebase account.
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  // User is fetched from Firestore and allowed to use his account.
  bool get isAuthorized => _user != null;

  UserEntity? get user => _user;

  String? get username => _username;

  String? get email => _email;

  String? get authUid => _firebaseAuth.currentUser?.uid;

  String get userName => _firebaseAuth.currentUser?.displayName ?? '';

  Stream<User?> get firebaseUser => Stream.value(_firebaseAuth.currentUser);

  AuthManager() {
    for (AuthMethod authMethod in [AuthMethod.email_password, AuthMethod.google_auth]) {
      switch (authMethod) {
        case AuthMethod.email_password:
          _emailAuthManager = EmailAuthManager();
          _signedInAuthMethod = AuthMethod.email_password;
          break;
        case AuthMethod.google_auth:
          _googleAuthManager = GoogleAuthManager();
          _signedInAuthMethod = AuthMethod.google_auth;
          break;
        default:
          // Not used by this app.
          continue;
      }
    }
    ensureUserLoaded();
  }

  setEmail(String email) {
    _email = email;
  }

  Future<AuthenticationResult> signInGoogle() async {
    AuthenticationResult authResult = await _googleAuthManager!.handleSignIn();
    if (authResult != AuthenticationResult.success) {
      return authResult;
    }
    _logger.log(Level.INFO, 'Authenticated with Google with success');
    return await _signIn(email: _googleAuthManager!.email, authUid: _googleAuthManager!.authUid);
  }

  // Make sure the user data is loaded from firebaseDb before doing any authorized operations.
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
        case AuthMethod.google_auth:
          username = _firebaseAuth.currentUser!.email!;
          final isConnectedToInternet = await _connectivityManager.hasInternetConnection();
          if (isConnectedToInternet) {
            if (_googleAuthManager!.authUid.isEmpty) {
              await signInGoogle();
            }
            authUid = _googleAuthManager!.authUid;
          } else {
            authUid = _firebaseAuth.currentUser!.uid;
          }
          break;
        case AuthMethod.email_password:
          username = _firebaseAuth.currentUser!.email!;
          authUid = _emailAuthManager!.authUid;
          break;
        default:
          _logger.log(Level.WARNING, 'Unknown auth method.');
          return false;
      }
      if (authUid.isEmpty) {
        _logger.log(Level.WARNING, 'Auth uid is empty.');
        return false;
      }
      _user = await _loadUser(authUid: authUid);
      if (_user != null) {
        _username = username;
        return true;
      }
    }
    _logger.log(Level.WARNING, 'Failed to initialize user');
    return false;
  }

  Future<void> signOut() async {
    switch (_signedInAuthMethod) {
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

  Future<AuthenticationResult> _signIn({required String email, required String authUid}) async {
    _logger.log(Level.INFO, 'Starting NextSense user check.');
    _user =
        (await _loadUser(authUid: authUid) ?? await _createNewUser(email: email, authUid: authUid));

    if (_user == null) {
      await signOut();
      return AuthenticationResult.user_fetch_failed;
    }
    _username = email;
    syncUserIdWithDatabase(authUid);
    return AuthenticationResult.success;
  }

  // Load user from Firestore and update some data
  Future<UserEntity?> _loadUser({required String authUid}) async {
    final UserEntity? user = await _fetchUserFromFirebaseRealtimeDb(authUid);
    if (user == null) {
      _logger.log(Level.WARNING, 'Failed to fetch user from Firestore.');
      return null;
    }
    return user;
  }

  Future<UserEntity?> _fetchUserFromFirebaseRealtimeDb(String authUid) async {
    final userEntity =
        await firebaseRealTimeDb.getEntity(UserEntity.instance, UserEntity.table.where(authUid));
    return userEntity;
  }

  Future<UserEntity> _createNewUser({required String email, required String authUid}) async {
    final user = UserEntity.instance;
    user.setEmail(email);
    user.setUserName(userName);
    await firebaseRealTimeDb.setEntity(user, UserEntity.table.where(authUid));
    return user;
  }

  void syncUserIdWithDatabase(String userId) {
    firebaseRealTimeDb.setUserId(userId);
  }
}
