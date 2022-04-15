import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/environment.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SignInScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SignInScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  final username = ValueNotifier<String>("");
  final password = ValueNotifier<String>("");

  String errorMsg = '';

  bool get hadPairedDevice => _deviceManager.getLastPairedDevice() != null;

  void init() async {
    if (envGet(EnvironmentKey.USERNAME).isNotEmpty) {
      loadCredentialsFromEnvironment();
    }
  }

  void loadCredentialsFromEnvironment() {
    username.value = envGet(EnvironmentKey.USERNAME, fallback: "");
    password.value = envGet(EnvironmentKey.PASSWORD, fallback: "");
  }

  Future<AuthenticationResult> signIn() async {
    errorMsg = '';
    notifyListeners();
    setBusy(true);
    AuthenticationResult authResult =
      await _authManager.signIn(username.value, password.value);
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
          errorMsg = 'Unknown error occured';
          break;
      }
      notifyListeners();
    }

    return authResult;
  }

  Future<bool> loadCurrentStudy() async {
    // Load the study data.
    final user = _authManager.user!;

    final studyId = user.getValue(UserKey.study);
    DateTime? studyStartDate = user.getStudyStartDate();
    DateTime? studyEndDate = user.getStudyEndDate();

    if (studyStartDate == null || studyEndDate == null) {
      _logger.log(Level.SEVERE,
          'Error when trying to load the study ${studyId}: '
              'study start or end date are null');
      return false;
    }

    bool studyLoaded = await _studyManager.loadCurrentStudy(
      studyId,
      studyStartDate,
      studyEndDate,
    );

    return studyLoaded;
  }

  Future<bool> connectToLastPairedDevice() async {
    return _deviceManager.connectLastPairedDevice();
  }
}