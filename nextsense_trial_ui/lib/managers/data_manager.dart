import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DataManager {

  final CustomLogPrinter _logger = CustomLogPrinter('DataManager');

  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  bool userLoaded = false;
  bool userStudyDataLoaded = false;

  Future<bool> loadUser() async {
    userLoaded = await _authManager.ensureUserLoaded();
    if (!userLoaded) {
      _logger.log(Level.WARNING,
          'Failed to load user. Fallback to signup');
      return false;
    }
    userLoaded = true;
    return true;
  }

  Future<bool> loadUserStudyData() async {
    await _studyManager.loadCurrentStudy();
    await _studyManager.loadScheduledProtocols();
    await _surveyManager.loadScheduledSurveys();
    // Mark study initialized so we can load things from cache
    await _studyManager.setStudyInitialized(true);

    userStudyDataLoaded = true;
    return true;
  }

  Future<bool> loadUserData() async {
    bool loaded = await loadUser();
    if (userLoaded) {
      loaded = await loadUserStudyData();
    }
    return loaded;
  }

  Future<bool> switchCurrentStudy(EnrolledStudy enrolledStudy) async {
      _authManager.user!.setValue(UserKey.current_study, enrolledStudy.id);
      await _firestoreManager.persistEntity(_authManager.user!);
      return await loadUserData();
  }
}