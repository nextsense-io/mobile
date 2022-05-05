import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SignInScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SignInScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final Flavor _flavor = getIt<Flavor>();

  final username = ValueNotifier<String>("");
  final password = ValueNotifier<String>("");

  String errorMsg = '';

  bool get hadPairedDevice => _deviceManager.hadPairedDevice;
  List<AuthMethod> get authMethods => _flavor.authMethods;
  String get appTitle => _flavor.appTitle;

  void init() async {
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
    try {
      return await _studyManager.loadCurrentStudy();
    } catch (e, stacktrace) {
      _logger.log(Level.SEVERE,
          'Failed to load dashboard data: '
              '${e.toString()}, ${stacktrace.toString()}');
      setBusy(false);
      return false;
    }
  }

  Future<bool> connectToLastPairedDevice() async {
    return _deviceManager.connectToLastPairedDevice();
  }
}