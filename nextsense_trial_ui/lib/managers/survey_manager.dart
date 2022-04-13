import 'package:collection/collection.dart';
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
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class SurveyManager {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyManager');

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();

  List<Survey>? _surveys;

  List<ScheduledSurvey> scheduledSurveys = [];

  // Group by planned survey id for stats
  Map<String, List<ScheduledSurvey>> _scheduledSurveysByPlannedSurveyId = {};

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
  Future loadScheduledSurveys() async {
    if (_surveys == null) {
      _surveys = await _loadSurveys();
    }

    scheduledSurveys.clear();
    _scheduledSurveysByPlannedSurveyId.clear();

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
        // This value must be unique for each different survey
        String scheduledSurveyKey =
            "day_${day.dayNumber}_${plannedSurvey.surveyId}"
            "_${plannedSurvey.period.name}";

        ScheduledSurvey scheduledSurvey = ScheduledSurvey(
            await _firestoreManager.queryEntity(
                [Table.users, Table.scheduled_surveys],
                [_authManager.getUserCode()!, scheduledSurveyKey]),
            survey, day, plannedSurvey.id);

        // Copy period from planned survey
        scheduledSurvey.setPeriod(plannedSurvey.period);

        if (scheduledSurvey.getValue(ScheduledSurveyKey.status) == null) {
          scheduledSurvey.setValue(ScheduledSurveyKey.status,
              SurveyState.not_started.name);
        }

        scheduledSurvey.save();

        scheduledSurveys.add(scheduledSurvey);

        // Add scheduled survey to group by planned survey id
        _scheduledSurveysByPlannedSurveyId.update(
            plannedSurvey.id, (value) => [...value, scheduledSurvey],
            ifAbsent: () => [scheduledSurvey]);
      }
    }

  }

  // Survey stats are calculated based on count of past and today surveys
  // from the same planned survey group (all scheduled surveys that were
  // generated from same planned survey)
  ScheduledSurveyStats getScheduledSurveyStats(ScheduledSurvey scheduledSurvey) {
    List<ScheduledSurvey> group =
        _scheduledSurveysByPlannedSurveyId[scheduledSurvey.plannedSurveyId] ?? [];

    final closestFutureMidnight = DateTime.now().closestFutureMidnight;
    List<ScheduledSurvey> pastAndTodayScheduledSurveys = group
        .where((scheduledSurvey) =>
            scheduledSurvey.day.date.isBefore(closestFutureMidnight))
        .toList();

    final int total = pastAndTodayScheduledSurveys.length;
    final int completed = pastAndTodayScheduledSurveys
        .where((_scheduledSurvey) => _scheduledSurvey.isCompleted).length;
    return ScheduledSurveyStats(total, completed);
  }

  Survey? getSurveyById(String surveyId) {
    return _surveys?.firstWhereOrNull((survey) => survey.id == surveyId);
  }



}

class ScheduledSurveyStats {
  // Total includes today and past surveys for same planned survey group
  final int total;

  // Completed today and past surveys for same planned survey group
  final int completed;

  ScheduledSurveyStats(this.total, this.completed);
}