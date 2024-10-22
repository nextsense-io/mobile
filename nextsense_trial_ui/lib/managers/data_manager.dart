import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/event_types_manager.dart';
import 'package:nextsense_trial_ui/managers/medication_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_trial_ui/managers/trial_ui_firestore_manager.dart';

class DataManager {

  final CustomLogPrinter _logger = CustomLogPrinter('DataManager');

  final AuthManager _authManager = getIt<AuthManager>();
  final EventTypesManager _eventTypesManager = getIt<EventTypesManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final MedicationManager _medicationManager = getIt<MedicationManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();
  final TrialUiFirestoreManager _firestoreManager = getIt<TrialUiFirestoreManager>();

  bool userLoaded = false;
  bool userStudyDataLoaded = false;

  Future<bool> loadUser() async {
    userLoaded = await _authManager.ensureUserLoaded();
    if (!userLoaded) {
      _logger.log(Level.WARNING, 'Failed to load user. Fallback to signup');
      return false;
    }
    userLoaded = true;
    _logger.log(Level.INFO, 'User loaded.');
    return true;
  }

  Future<bool> loadUserStudyData() async {
    _logger.log(Level.INFO, 'Starting to load event types data.');
    bool loaded = await _eventTypesManager.loadEventTypes();
    if (!loaded) return false;
    _logger.log(Level.INFO, 'Starting to load user study data.');
    loaded = await _studyManager.loadCurrentStudy();
    if (!loaded) return false;
    _logger.log(Level.INFO, 'Starting loadScheduledProtocols.');
    loaded = await _studyManager.loadScheduledProtocols();
    if (!loaded) return false;
    _logger.log(Level.INFO, 'Starting loadPlannedSurveys.');
    loaded = await _surveyManager.loadPlannedSurveys();
    if (!loaded) return false;
    _logger.log(Level.INFO, 'Starting loadAdhocSurveys.');
    loaded = await _surveyManager.loadAdhocSurveys();
    if (!loaded) return false;
    _logger.log(Level.INFO, 'Starting loadPlannedMedications.');
    loaded = await _medicationManager.loadPlannedMedications();
    if (!loaded) return false;
    await _sessionManager.loadCurrentSession();
    // Mark study initialized so we can load things from cache
    bool initialized = await _studyManager.setStudyScheduled(true);
    if (!initialized) {
      return false;
    }

    userStudyDataLoaded = true;
    _logger.log(Level.INFO, 'User study data loaded.');
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
      _authManager.user!.setValue(UserKey.current_study_id, enrolledStudy.id);
      bool success = await _firestoreManager.persistEntity(_authManager.user!);
      if (!success) {
        return false;
      }
      return await loadUserData();
  }
}