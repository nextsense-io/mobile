import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
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

  String get _currentStudyId => _studyManager.currentStudy!.id;


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

  // Load planned surveys from study and convert them to scheduled surveys
  // that persist in user table
  Future<bool> loadScheduledSurveys() async {
    final bool? studyInitialized = _studyManager.studyInitialized;

    if (studyInitialized == null) {
      throw("study not initialized. cannot load surveys");
    }

    // If study is initialized take surveys from cache
    _surveys = await _loadSurveys(fromCache: studyInitialized);

    scheduledSurveys.clear();
    _scheduledSurveysByPlannedSurveyId.clear();

    if (studyInitialized) {
      // If study already initialized, return scheduled surveys from cache
      _logger.log(Level.WARNING, 'Loading scheduled surveys from cache');
      List<ScheduledSurvey>? scheduledSurveys = await _loadScheduledSurveysFromCache();
      if (scheduledSurveys != null) {
        scheduledSurveys = await _loadScheduledSurveysFromCache();
      } else {
        return false;
      }
    } else {
      _logger.log(Level.WARNING,
          'Creating scheduled surveys based on planned surveys');

      List<PlannedSurvey>? plannedSurveys = await _studyManager.loadPlannedSurveys();
      if (plannedSurveys == null) {
        return false;
      }

      // Speed up queries by making parallel requests
      List<Future> futures = [];
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

          Future future = _firestoreManager.queryEntity(
              [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
              [_authManager.userCode!, _currentStudyId,
                scheduledSurveyKey]);

          future.then((firebaseEntity) {
            // Scheduled survey is created based on planned survey
            ScheduledSurvey scheduledSurvey = ScheduledSurvey(
                firebaseEntity,
                survey, day,
                plannedSurvey: plannedSurvey);

            // Copy period from planned survey
            scheduledSurvey.setPeriod(plannedSurvey.period);

            if (scheduledSurvey.getValue(ScheduledSurveyKey.status) == null) {
              scheduledSurvey.setValue(ScheduledSurveyKey.status,
                  SurveyState.not_started.name);
            }

            scheduledSurvey.save();

            scheduledSurveys.add(scheduledSurvey);
          });
          futures.add(future);
        }
      }

      await Future.wait(futures);

      // Make sure cache is up to date, need to query whole collection
      // Without this query undesired items can appear in cache
      await _queryScheduledSurveys();
    }

    // Make consistent order
    scheduledSurveys
        .sortBy((scheduledSurvey) => scheduledSurvey.plannedSurveyId);

    for (var scheduledSurvey in scheduledSurveys) {
      // Add scheduled survey to group by planned survey id
      _scheduledSurveysByPlannedSurveyId.update(
          scheduledSurvey.plannedSurveyId, (value) => [...value, scheduledSurvey],
          ifAbsent: () => [scheduledSurvey]);
    }
    return true;
  }

  Future<List<Survey>?> _loadSurveys({bool fromCache = false}) async {
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.surveys], [],
        fromCacheWithKey: fromCache ? Table.surveys.name() : null,
    );
    if (entities == null) {
      return null;
    }

    List<Survey> results = [];
    // Speed up queries by making parallel requests
    List<Future<bool>> futures = [];
    for (FirebaseEntity entity in entities) {
      final survey = Survey(entity);
      Future<bool> futureResult = survey.loadQuestions(fromCache: fromCache).then((loadResult) {
        if (!loadResult) {
          return false;
        }
        results.add(survey);
        return true;
      });
      futures.add(futureResult);
    }

    List<bool> futureResults = await Future.wait(futures);
    for (bool futureResult in futureResults) {
      if (!futureResult) {
        // Failed to load questions.
        return null;
      }
    }

    // Make consistent order
    results.sortBy((survey) => survey.id);

    return results;
  }

  Future<List<ScheduledSurvey>?> _loadScheduledSurveysFromCache() async {
    if (_surveys == null) {
      throw("Surveys not initialized");
    }

    List<FirebaseEntity>? entities =
        await _queryScheduledSurveys(fromCache: true);
    if (entities == null) {
      return null;
    }

    List<ScheduledSurvey> result = [];

    for (FirebaseEntity entity in entities) {
      final surveyId = entity.getValue(ScheduledSurveyKey.survey);
      final dayNumber = entity.getValue(ScheduledSurveyKey.day_number);
      Survey? survey = getSurveyById(surveyId);
      if (survey == null) {
        _logger.log(Level.SEVERE, 'Survey with id "$surveyId" not found');
        continue;
      }

      StudyDay? studyDay = _studyManager.getStudyDayByNumber(dayNumber);

      if (studyDay == null) {
        _logger.log(Level.SEVERE,
            'Study day with number "$dayNumber" not found.');
        continue;
      }

      final scheduledSurvey = ScheduledSurvey(entity, survey, studyDay);
      result.add(scheduledSurvey);
    }
    return result;
  }

  Future<List<FirebaseEntity>?> _queryScheduledSurveys(
      {bool fromCache = false}) async {
    String cacheKey = "${_currentStudyId}_${Table.scheduled_surveys.name()}";
    return await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
        [_authManager.userCode!, _currentStudyId],
        fromCacheWithKey: fromCache ? cacheKey : null);
  }
}

class ScheduledSurveyStats {
  // Total includes today and past surveys for same planned survey group
  final int total;

  // Completed today and past surveys for same planned survey group
  final int completed;

  ScheduledSurveyStats(this.total, this.completed);
}