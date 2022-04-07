import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:collection/collection.dart';

class SurveyManager {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyManager');

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();

  List<Survey>? _surveys;

  Future<List<Survey>> _loadSurveys() async {
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.surveys], []
    );

    List<Survey> result = [];

    for (FirebaseEntity entity in entities) {
      final survey = Survey(entity);
      // TODO(alex): load multiple surveys async to speedup
      await survey.loadQuestions();
      result.add(survey);
    }

    return result;

  }

  // Load planned surveys from study and convert them to scheduled surveys
  // that persist in user table
  Future<List<ScheduledSurvey>> loadScheduledSurveys() async {
    if (_surveys == null) {
      _surveys = await _loadSurveys();
    }

    List<ScheduledSurvey> result = [];

    List<PlannedSurvey> plannedSurveys =
        await _studyManager.loadPlannedSurveys();

    for (var plannedSurvey in plannedSurveys) {
      Survey? survey = getSurveyById(plannedSurvey.surveyId);

      if (survey == null) {
        _logger.log(Level.WARNING,
            'Planned survey "${plannedSurvey.surveyId}" not found');
        continue;
      }

      for (var day in plannedSurvey.days) {
        String scheduledSurveyKey =
            "day_${day.dayNumber}";

        ScheduledSurvey scheduledSurvey = ScheduledSurvey(
            await _firestoreManager.queryEntity(
                [Table.users, Table.scheduled_surveys],
                [_authManager.getUserCode()!, scheduledSurveyKey]),
            survey, day);

        if (scheduledSurvey.getValue(ScheduledSurveyKey.status) == null) {
          scheduledSurvey.setValue(ScheduledSurveyKey.status,
              SurveyState.not_started.name);
        }

        scheduledSurvey.save();

        result.add(scheduledSurvey);
      }
    }

    return result;

  }


  Survey? getSurveyById(String surveyId) {
    return _surveys?.firstWhereOrNull((survey) => survey.id == surveyId);
  }



}