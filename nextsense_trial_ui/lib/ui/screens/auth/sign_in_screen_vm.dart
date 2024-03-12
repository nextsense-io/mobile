import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class SignInScreenViewModel extends ViewModel {
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final ConnectivityManager _connectivityManager = getIt<ConnectivityManager>();
  final Flavor _flavor = getIt<Flavor>();

  final username = ValueNotifier<String>("");
  final password = ValueNotifier<String>("");

  bool internetConnection = true;
  String errorMsg = "";
  bool popupErrorMsg = false;

  bool get hadPairedDevice => _authManager.getLastPairedMacAddress() != null;
  List<AuthMethod> get authMethods => _flavor.authMethods;
  String get appTitle => _flavor.appTitle;
  bool get isTempPassword => _authManager.user!.isTempPassword();
  bool get showStudyIntro => _studyManager.currentEnrolledStudy != null &&
      _studyManager.currentEnrolledStudy!.showIntro;
  String? initialErrorMessage;

  SignInScreenViewModel({this.initialErrorMessage}) {
    errorMsg = initialErrorMessage ?? "";
    popupErrorMsg = initialErrorMessage != null;
  }

  @override
  void init() async {
    super.init();
    if (envGet(EnvironmentKey.USERNAME).isNotEmpty) {
      loadCredentialsFromEnvironment();
    }
    _checkInternetConnection();
  }

  void _checkInternetConnection() {
    if (_connectivityManager.isNone) {
      internetConnection = false;
      errorMsg = "An internet connection is needed to login.";
    } else {
      internetConnection = true;
    }
  }

  void loadCredentialsFromEnvironment() {
    username.value = envGet(EnvironmentKey.USERNAME, fallback: "");
    password.value = envGet(EnvironmentKey.PASSWORD, fallback: "");
  }

  Future<AuthenticationResult> signIn(AuthMethod authMethod) async {
    notifyListeners();
    errorMsg = '';
    _checkInternetConnection();
    notifyListeners();
    if (!internetConnection) {
      return AuthenticationResult.connection_error;
    }
    setBusy(true);
    notifyListeners();
    AuthenticationResult authResult;
    switch (authMethod) {
      case AuthMethod.email_password:
        authResult = await _authManager.signInEmailPassword(
            username.value, password.value);
        break;
      case AuthMethod.user_code:
        authResult = await _authManager.signInNextSense(
            username.value, password.value);
        break;
      case AuthMethod.google_auth:
        authResult = await _authManager.signInGoogle();
        break;
    }
    if (authResult != AuthenticationResult.success) {
      switch(authResult) {
        case AuthenticationResult.user_fetch_failed:
        case AuthenticationResult.invalid_user_setup:
        case AuthenticationResult.invalid_username_or_password:
          errorMsg = 'Invalid username or password';
          break;
        case AuthenticationResult.connection_error:
          errorMsg = 'Connection error';
          break;
        default:
          errorMsg = 'Unknown error occurred';
          break;
      }
      setBusy(false);
      notifyListeners();
    }
    return authResult;
  }

  Future<bool> loadCurrentStudy() async {
    setBusy(true);
    bool loaded = await _dataManager.loadUserStudyData();
    setBusy(false);
    return loaded;
  }

  Future<bool> connectToLastPairedDevice() async {
    setBusy(true);
    bool connected = await _deviceManager.connectToLastPairedDevice(
        _authManager.getLastPairedMacAddress());
    setBusy(false);
    return connected;
  }

  Future<bool> markCurrentStudyShown() async {
    return await _studyManager.markEnrolledStudyShown();
  }

  void exit() {
    _deviceManager.dispose();
    NextsenseBase.setFlutterActivityActive(false);
    SystemNavigator.pop();
  }
}