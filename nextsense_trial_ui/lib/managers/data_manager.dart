
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DataManager {

  final CustomLogPrinter _logger = CustomLogPrinter('DataManager');

  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();

  bool userDataLoaded = false;

  Future<bool> loadUserData() async {
    bool userLoaded = await _authManager.ensureUserLoaded();
    if (!userLoaded) {
      _logger.log(Level.WARNING,
          'Failed to load user. Fallback to signup');
      return false;
    }
    await _studyManager.loadCurrentStudy();
    await _studyManager.loadScheduledProtocols();
    await _surveyManager.loadScheduledSurveys();
    // Mark study initialized so we can load things from cache
    await _studyManager.setStudyInitialized(true);

    userDataLoaded = true;
    return true;
  }

}