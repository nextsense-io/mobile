import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, Survey> _surveys = {};
  List<ScheduledSurvey> scheduledSurveys = [];

  // Group by planned survey id for stats
  Map<String, List<ScheduledSurvey>> _scheduledSurveysByPlannedSurveyId = {};

  String get _currentStudyId => _studyManager.currentStudy!.id;

  SurveyStats _getSurveyStats(List<ScheduledSurvey> scheduledSurveys, DateTime dateUntil) {
    List<ScheduledSurvey> pastAndTodayScheduledSurveys = scheduledSurveys
        .where((scheduledSurvey) => scheduledSurvey.day.date.isBefore(dateUntil)).toList();

    final int total = pastAndTodayScheduledSurveys.length;
    final int completed = pastAndTodayScheduledSurveys
        .where((_scheduledSurvey) => _scheduledSurvey.isCompleted).length;
    return SurveyStats(total, completed);
  }

  // Scheduled survey stats are calculated based on count of past and today surveys from the same
  // planned survey group (all scheduled surveys that were generated from same planned survey).
  SurveyStats getScheduledSurveyStats(ScheduledSurvey scheduledSurvey) {
    List<ScheduledSurvey> group =
        _scheduledSurveysByPlannedSurveyId[scheduledSurvey.plannedSurveyId] ?? [];
    return _getSurveyStats(group, DateTime.now().closestFutureMidnight);
  }

  // Global survey stats are calculated based on count of past and today surveys from all scheduled
  // surveys.
  SurveyStats getGlobalSurveyStats() {
    return _getSurveyStats(scheduledSurveys, DateTime.now().closestFutureMidnight);
  }

  Survey? getSurveyById(String surveyId) {
    return _surveys[surveyId];
  }

  // Load planned surveys from study adhoc list.
  Future<bool> loadAdhocSurveys() async {
    for (String surveyId in _studyManager.currentStudy!.getAllowedSurveys()) {
      if (!_surveys.containsKey(surveyId)) {
        Survey? survey = await _loadSurvey(surveyId);
        if (survey == null) {
          return false;
        }
        bool loaded = await survey.loadQuestions(
            fromCache: _studyManager.studyInitialized ?? false);
        if (loaded == false) {
          return false;
        }
      }
    }
    return true;
  }

  // Load planned surveys from study and convert them to scheduled surveys that persist in the user
  // table.
  Future<bool> loadScheduledSurveys() async {
    final bool? studyInitialized = _studyManager.studyInitialized;

    if (studyInitialized == null) {
      throw("study not initialized. cannot load surveys");
    }

    scheduledSurveys.clear();
    _scheduledSurveysByPlannedSurveyId.clear();

    if (studyInitialized) {
      // If study already initialized, return scheduled surveys from cache
      _logger.log(Level.WARNING, 'Loading scheduled surveys from cache');
      List<ScheduledSurvey>? scheduledSurveysFromCache = await _loadScheduledSurveysFromCache();
      if (scheduledSurveysFromCache != null) {
        scheduledSurveys = scheduledSurveysFromCache;
        for (ScheduledSurvey scheduledSurvey in scheduledSurveysFromCache) {
          if (!_surveys.containsKey(scheduledSurvey.survey.id)) {
            await _loadSurvey(scheduledSurvey.survey.id);
          }
        }
      } else {
        return false;
      }
    } else {
      _logger.log(Level.WARNING, 'Creating scheduled surveys based on planned surveys');

      List<PlannedSurvey>? plannedSurveys = await _studyManager.loadPlannedSurveys();
      if (plannedSurveys == null) {
        return false;
      }
      for (PlannedSurvey plannedSurvey in plannedSurveys) {
        if (!_surveys.containsKey(plannedSurvey.surveyId)) {
           await _loadSurvey(plannedSurvey.surveyId, fromCache: studyInitialized);
        }
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
          String scheduledSurveyKey = "day_${day.dayNumber}_${plannedSurvey.surveyId}"
              "_${plannedSurvey.period.name}";

          Future future = _firestoreManager.queryEntity(
              [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
              [_authManager.userCode!, _currentStudyId, scheduledSurveyKey]);

          future.then((firebaseEntity) {
            // Scheduled survey is created based on planned survey
            ScheduledSurvey scheduledSurvey = ScheduledSurvey(
                firebaseEntity, survey, day, plannedSurvey: plannedSurvey);

            // Copy period from planned survey
            scheduledSurvey.setPeriod(plannedSurvey.period);

            if (scheduledSurvey.getValue(ScheduledSurveyKey.status) == null) {
              scheduledSurvey.setValue(ScheduledSurveyKey.status, SurveyState.not_started.name);
            }

            scheduledSurvey.save();

            scheduledSurveys.add(scheduledSurvey);
          });
          futures.add(future);
        }
      }

      await Future.wait(futures);
    }

    await _loadSurveysQuestions(fromCache: studyInitialized);

    // Make sure cache is up to date, need to query whole collection
    // Without this query undesired items can appear in cache
    await _queryScheduledSurveys();

    // Make consistent order
    scheduledSurveys.sortBy((scheduledSurvey) => scheduledSurvey.plannedSurveyId);

    for (var scheduledSurvey in scheduledSurveys) {
      // Add scheduled survey to group by planned survey id.
      _scheduledSurveysByPlannedSurveyId.update(
          scheduledSurvey.plannedSurveyId, (value) => [...value, scheduledSurvey],
          ifAbsent: () => [scheduledSurvey]);
    }
    return true;
  }

  Future<ScheduledSurvey?> queryScheduledSurvey(String scheduledSurveyId) async {
    FirebaseEntity? scheduledSurveyEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
        [_authManager.userCode!, _currentStudyId, scheduledSurveyId]);
    if (scheduledSurveyEntity != null) {
      final plannedSurveyId = (scheduledSurveyEntity.getValue(ScheduledSurveyKey.planned_survey)
          as DocumentReference).id;
      FirebaseEntity? plannedSurveyEntity = await _firestoreManager.queryEntity(
          [Table.studies, Table.planned_surveys], [_currentStudyId, plannedSurveyId]);
      if (plannedSurveyEntity != null) {
        PlannedSurvey plannedSurvey = PlannedSurvey(plannedSurveyEntity,
            _studyManager.currentStudyStartDate!, _studyManager.currentStudyEndDate!);
        Survey? survey = getSurveyById(plannedSurvey.surveyId);
        if (survey == null) {
          return null;
        }
        return ScheduledSurvey(scheduledSurveyEntity, survey, StudyDay(DateTime.now(),
            scheduledSurveyEntity.getValue(ScheduledSurveyKey.day_number)),
            plannedSurvey: plannedSurvey);
      }
    }
    return null;
  }

  Future<Survey?> _loadSurvey(String surveyId, {bool fromCache = false}) async {
    FirebaseEntity? entity = await _firestoreManager.queryEntity(
      [Table.surveys], [surveyId], fromCacheWithKey: fromCache ? Table.surveys.name() : null,
    );
    if (entity == null) {
      throw Exception('$surveyId not found in the survey table.');
    }
    Survey survey = Survey(entity);
    _surveys[surveyId] = survey;
    return survey;
  }

  Future _loadSurveysQuestions({bool fromCache = false}) async {
    // Speed up queries by making parallel requests.
    List<Future<bool>> futures = [];
    for (Survey survey in _surveys.values) {
      Future<bool> futureResult = survey.loadQuestions(fromCache: fromCache).then((loadResult) {
        if (!loadResult) {
          return false;
        }
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
  }

  Future<List<ScheduledSurvey>?> _loadScheduledSurveysFromCache() async {
    if (_surveys == null) {
      throw("Surveys not initialized");
    }

    List<FirebaseEntity>? entities = await _queryScheduledSurveys(fromCache: true);
    if (entities == null) {
      return null;
    }

    List<ScheduledSurvey> result = [];

    for (FirebaseEntity entity in entities) {
      final surveyId = entity.getValue(ScheduledSurveyKey.survey);
      final dayNumber = entity.getValue(ScheduledSurveyKey.day_number);
      Survey? survey = getSurveyById(surveyId);
      if (survey == null) {
        survey = await _loadSurvey(surveyId);
        if (survey == null) {
          _logger.log(Level.SEVERE, 'Survey with id "$surveyId" not found');
          continue;
        }
      }

      StudyDay? studyDay = _studyManager.getStudyDayByNumber(dayNumber);

      if (studyDay == null) {
        _logger.log(Level.SEVERE, 'Study day with number "$dayNumber" not found.');
        continue;
      }

      final scheduledSurvey = ScheduledSurvey(entity, survey, studyDay);
      _logger.log(Level.INFO, 'loaded scheduled survey: ' + scheduledSurvey.id + ' on day ' +
          scheduledSurvey.day.dayNumber.toString() + '. State: ' + scheduledSurvey.state.name);
      result.add(scheduledSurvey);
    }
    return result;
  }

  Future<List<FirebaseEntity>?> _queryScheduledSurveys({bool fromCache = false}) async {
    String cacheKey = "${_currentStudyId}_${Table.scheduled_surveys.name()}";
    return await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
        [_authManager.userCode!, _currentStudyId],
        fromCacheWithKey: fromCache ? cacheKey : null);
  }
}

class SurveyStats {
  // Total includes today and past surveys for a planned survey group or all surveys.
  final int total;

  // Completed today and past surveys for a planned survey group or all surveys,
  final int completed;

  SurveyStats(this.total, this.completed);
}