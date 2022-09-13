import 'package:flutter/cupertino.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SignInScreenViewModel extends ViewModel {
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Flavor _flavor = getIt<Flavor>();

  final username = ValueNotifier<String>("");
  final password = ValueNotifier<String>("");

  String errorMsg = '';

  bool get hadPairedDevice => _deviceManager.hadPairedDevice;
  List<AuthMethod> get authMethods => _flavor.authMethods;
  String get appTitle => _flavor.appTitle;
  bool get isTempPassword => _authManager.user!.isTempPassword();
  bool get studyIntroShown => _studyManager.currentEnrolledStudy != null &&
      _studyManager.currentEnrolledStudy!.intro_shown;

  @override
  void init() async {
    super.init();
    if (envGet(EnvironmentKey.USERNAME).isNotEmpty) {
      loadCredentialsFromEnvironment();
    }
  }

  void loadCredentialsFromEnvironment() {
    username.value = envGet(EnvironmentKey.USERNAME, fallback: "");
    password.value = envGet(EnvironmentKey.PASSWORD, fallback: "");
  }

  Future<AuthenticationResult> signIn(AuthMethod authMethod) async {
    errorMsg = '';
    notifyListeners();
    setBusy(true);
    AuthenticationResult authResult;
    switch (authMethod) {
      case AuthMethod.user_code:
        authResult = await _authManager.signInNextSense(
            username.value, password.value);
        break;
      case AuthMethod.google_auth:
        authResult = await _authManager.signInGoogle();
        break;
    }
    setBusy(false);
    if (authResult != AuthenticationResult.success) {
      switch(authResult) {
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
    bool connected = await _deviceManager.connectToLastPairedDevice();
    setBusy(false);
    return connected;
  }

  Future<bool> markCurrentStudyShown() async {
    return await _studyManager.markEnrolledStudyShown();
  }
}