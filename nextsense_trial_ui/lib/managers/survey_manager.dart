import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/planned_session.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/adhoc_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey_result.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class SurveyManager {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyManager');
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Preferences _preferences = getIt<Preferences>();

  Map<String, Survey> _surveys = {};
  List<ScheduledSurvey> _scheduledSurveys = [];
  List<PlannedSurvey>? _plannedSurveys;
  List<PlannedSurvey> _adhocPlannedSurveys = [];
  // Group by planned survey id for stats
  Map<String, List<ScheduledSurvey>> _scheduledSurveysByPlannedSurveyId = {};

  String get _currentStudyId => _studyManager.currentStudy!.id;

  bool get hasScheduledSurveys => _scheduledSurveys.isNotEmpty;
  List<PlannedSurvey> get allowedAdhocSurveys => _adhocPlannedSurveys;
  List<ScheduledSurvey> get scheduledSurveys => _scheduledSurveys;
  bool get surveysEnabled => scheduledSurveys.isNotEmpty;

  SurveyStats _getSurveyStats(List<ScheduledSurvey> scheduledSurveys, DateTime dateUntil) {
    List<ScheduledSurvey> pastAndTodayScheduledSurveys = scheduledSurveys
        .where((scheduledSurvey) => scheduledSurvey.day!= null &&
        scheduledSurvey.day!.date.isBefore(dateUntil)).toList();

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

  // Load surveys from study adhoc list.
  Future<bool> loadAdhocSurveys() async {
    _logger.log(Level.INFO, "Loading adhoc surveys");
    for (PlannedSurvey adhocPlannedSurvey in _adhocPlannedSurveys) {
      if (!_surveys.containsKey(adhocPlannedSurvey.surveyId)) {
        _logger.log(Level.INFO, "Loading adhoc survey $adhocPlannedSurvey.surveyId");
        Survey? survey = await _loadSurvey(adhocPlannedSurvey.surveyId);
        if (survey == null) {
          return false;
        }
      }
    }
    return true;
  }

  // Load planned surveys from study and convert them to scheduled surveys that persist in the user
  // table.
  Future<bool> loadPlannedSurveys() async {
    final bool? studyScheduled = _studyManager.studyScheduled;
    if (!_studyManager.studyScheduled!) {
      _surveys = {};
    }

    if (studyScheduled == null) {
      throw("study not initialized. cannot load surveys");
    }

    _scheduledSurveys.clear();
    _scheduledSurveysByPlannedSurveyId.clear();
    _adhocPlannedSurveys.clear();

    bool fromCache = _preferences.getBool(PreferenceKey.studyDataCached);
    _plannedSurveys = await _studyManager.loadPlannedSurveys(studyScheduled && fromCache);
    if (_plannedSurveys == null) {
      return false;
    }

    for (var plannedSurvey in _plannedSurveys!) {
      if (plannedSurvey.scheduleType == ScheduleType.adhoc) {
        _adhocPlannedSurveys.add(plannedSurvey);
      }
    }

    if (studyScheduled) {
      // If study already scheduled, return scheduled surveys from cache if present.
      _logger.log(Level.WARNING, 'Loading scheduled surveys from cache');
      List<ScheduledSurvey>? scheduledSurveys = await _loadScheduledSurveys(fromCache);
      if (scheduledSurveys != null) {
        _scheduledSurveys = scheduledSurveys;
        for (ScheduledSurvey scheduledSurvey in scheduledSurveys) {
          if (!_surveys.containsKey(scheduledSurvey.survey.id)) {
            await _loadSurvey(scheduledSurvey.survey.id, fromCache: fromCache);
          }
        }
      } else {
        return false;
      }
    } else {
      _logger.log(Level.WARNING, 'Creating scheduled surveys based on planned surveys');

      for (PlannedSurvey plannedSurvey in _plannedSurveys!) {
        if (!_surveys.containsKey(plannedSurvey.surveyId)) {
           await _loadSurvey(plannedSurvey.surveyId);
        }
      }

      // Speed up queries by making parallel requests
      List<Future> futures = [];
      for (var plannedSurvey in _plannedSurveys!) {
        Survey? survey = getSurveyById(plannedSurvey.surveyId);

        if (survey == null) {
          _logger.log(Level.WARNING,
              'Planned survey "${plannedSurvey.surveyId}" not found');
          continue;
        }

        for (var day in plannedSurvey.days ?? []) {
          Future future = _firestoreManager.addAutoIdEntity(
              [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
              [_authManager.user!.id, _currentStudyId]);

          future.then((firebaseEntity) {
            // Scheduled survey is created based on planned survey
            ScheduledSurvey scheduledSurvey = ScheduledSurvey(
                firebaseEntity, survey: survey, day: day, plannedSurvey: plannedSurvey);

            // Copy period from planned survey
            scheduledSurvey.setPeriod(plannedSurvey.period!);

            if (scheduledSurvey.getValue(ScheduledSurveyKey.status) == null) {
              scheduledSurvey.setValue(ScheduledSurveyKey.status, SurveyState.not_started.name);
            }

            scheduledSurvey.save();

            _scheduledSurveys.add(scheduledSurvey);
          });
          futures.add(future);
        }
      }

      await Future.wait(futures);
    }

    bool loaded = await _loadSurveysQuestions(fromCache: fromCache);
    if (loaded == false) {
      return false;
    }

    // Make sure cache is up to date, need to query whole collection
    // Without this query undesired items can appear in cache
    await _queryScheduledSurveys();

    // Make consistent order
    _scheduledSurveys.sortBy((scheduledSurvey) => scheduledSurvey.plannedSurveyId);

    for (var scheduledSurvey in _scheduledSurveys) {
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
        [_authManager.user!.id, _currentStudyId, scheduledSurveyId]);
    if (scheduledSurveyEntity != null) {
      final plannedSurveyId = (scheduledSurveyEntity.getValue(ScheduledSurveyKey.planned_survey)
          as DocumentReference).id;
      FirebaseEntity? plannedSurveyEntity = await _firestoreManager.queryEntity(
          [Table.studies, Table.planned_surveys], [_currentStudyId, plannedSurveyId]);
      if (plannedSurveyEntity != null) {
        PlannedSurvey plannedSurvey = PlannedSurvey(plannedSurveyEntity,
            studyStartDate: _studyManager.currentStudyStartDate,
            studyEndDate: _studyManager.currentStudyEndDate);
        Survey? survey = getSurveyById(plannedSurvey.surveyId);
        if (survey == null) {
          return null;
        }
        return ScheduledSurvey(scheduledSurveyEntity, survey: survey, day: StudyDay(DateTime.now(),
            scheduledSurveyEntity.getValue(ScheduledSurveyKey.day_number)),
            plannedSurvey: plannedSurvey);
      }
    }
    return null;
  }

  PlannedSurvey _getPlannedSurveyById(String plannedSurveyId) {
    return _plannedSurveys!.firstWhere((plannedSurvey) => plannedSurvey.id == plannedSurveyId);
  }

  Future<ScheduledSurvey?> scheduleSurveyTrigger(PlannedSession triggerPlannedSession) async {
    if (triggerPlannedSession.triggersConditionalSurveyId == null) {
      _logger.log(Level.WARNING, 'triggerPlannedSession.triggersConditionalSurveyId is null');
      return null;
    }
    PlannedSurvey? triggeredPlannedSurvey = _getPlannedSurveyById(
        triggerPlannedSession.triggersConditionalSurveyId!);
    if (triggeredPlannedSurvey == null) {
      _logger.log(Level.WARNING, 'triggered planned survey '
          '${triggerPlannedSession.triggersConditionalSurveyId} not found');
      return null;
    }

    FirebaseEntity entity = await _firestoreManager.addAutoIdEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_sessions],
        [_authManager.user!.id, _currentStudyId]);

    ScheduledSurvey scheduledSurvey = ScheduledSurvey.fromSurveyTrigger(
        entity, plannedSurvey: triggeredPlannedSurvey,
        survey: getSurveyById(triggeredPlannedSurvey.surveyId)!,
        triggeredBy: triggerPlannedSession.id);
    await scheduledSurvey.save();
    return scheduledSurvey;
  }

  // Creates an Adhoc survey record in the database and return a reference to it.
  Future<AdhocSurvey> createAdhocSurvey(PlannedSurvey plannedSurvey) async {
    if (plannedSurvey.scheduleType != ScheduleType.adhoc) {
      throw Exception('Planned survey is not an adhoc survey');
    }
    FirebaseEntity adhocSurveyEntity = await _firestoreManager.addAutoIdEntity([
      Table.users, Table.enrolled_studies, Table.adhoc_surveys], [
      _authManager.user!.id, _currentStudyId]);
    return AdhocSurvey(adhocSurveyEntity, plannedSurvey.id,
        getSurveyById(plannedSurvey.surveyId)!, _currentStudyId);
  }

  Future<SurveyResult> startSurvey(RunnableSurvey runnableSurvey) async {
    FirebaseEntity surveyResultEntity = await _firestoreManager.addAutoIdEntity([
      Table.survey_results], []);
    final surveyResult = SurveyResult(surveyResultEntity);
    surveyResult.setUserId(_authManager.user!.id);
    surveyResult.setStudyId(_currentStudyId);
    surveyResult.setSurveyId(runnableSurvey.survey.id);
    surveyResult.setPlannedSurveyId(runnableSurvey.plannedSurveyId);
    if (runnableSurvey.scheduledSurveyId != null) {
      surveyResult.setScheduledSurveyId(runnableSurvey.scheduledSurveyId!);
    }
    DateTime now = DateTime.now();
    surveyResult.setStartDateTime(now);
    surveyResult.setUpdatedAt(now);
    await surveyResult.save();
    runnableSurvey.update(state: SurveyState.started, resultId: surveyResult.id);
    return surveyResult;
  }

  Future<bool> stopSurvey({required RunnableSurvey runnableSurvey, required String surveyResultId,
      required SurveyState state, Map<String, dynamic>? data}) async {
    DateTime now = DateTime.now();
    FirebaseEntity? surveyResultEntity = await _firestoreManager.queryEntity([
      Table.survey_results], [surveyResultId]);
    if (surveyResultEntity == null) {
      throw Exception('Survey result $surveyResultId not found.');
    }
    final surveyResult = SurveyResult(surveyResultEntity);
    if (data != null) {
      surveyResult.setData(data);
    }
    if (state == SurveyState.completed) {
      surveyResult.setEndDateTime(now);
    }
    surveyResult.setUpdatedAt(now);
    await surveyResult.save();
    runnableSurvey.update(state: state, resultId: surveyResult.id);
    return true;
  }

  Future<SurveyResult?> getSurveyResult(String surveyResultId) async {
    FirebaseEntity? surveyResultEntity = await _firestoreManager.queryEntity([
        Table.survey_results], [surveyResultId]);
    if (surveyResultEntity == null) {
      _logger.log(Level.SEVERE, 'Survey result with id "$surveyResultId" not found');
      return null;
    }
    return SurveyResult(surveyResultEntity);
  }

  Future<Survey?> _loadSurvey(String surveyId, {bool fromCache = false}) async {
    FirebaseEntity? entity = await _firestoreManager.queryEntity(
      [Table.surveys], [surveyId], fromCacheWithKey: fromCache ? Table.surveys.name() : null,
    );
    if (entity == null) {
      throw Exception('$surveyId not found in the survey table.');
    }
    Survey survey = Survey(entity);
    bool loaded = await survey.loadQuestions(fromCache: fromCache);
    if (!loaded) {
      throw Exception('$surveyId question not loaded.');
    }
    _surveys[surveyId] = survey;
    return survey;
  }

  Future<bool> _loadSurveysQuestions({bool fromCache = false}) async {
    // Speed up queries by making parallel requests.
    List<Future<bool>> futures = [];
    for (Survey survey in _surveys.values) {
      if (survey.getQuestions() != null) {
        continue;
      }
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
        return false;
      }
    }
    return true;
  }

  Future<List<ScheduledSurvey>?> _loadScheduledSurveys(bool fromCache) async {
    if (_surveys == null) {
      throw("Surveys not initialized");
    }

    List<FirebaseEntity>? entities = await _queryScheduledSurveys(fromCache: fromCache);
    if (entities == null) {
      return null;
    }

    List<ScheduledSurvey> result = [];

    for (FirebaseEntity entity in entities) {
      final surveyId = entity.getValue(ScheduledSurveyKey.survey_id);
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

      final scheduledSurvey = ScheduledSurvey(entity, survey: survey, day: studyDay);
      _logger.log(Level.INFO, 'loaded scheduled survey: ' + scheduledSurvey.id + ' on day ' +
          scheduledSurvey.day!.dayNumber.toString() + '. State: ' + scheduledSurvey.state.name);
      result.add(scheduledSurvey);
    }
    return result;
  }

  Future<List<FirebaseEntity>?> _queryScheduledSurveys({bool fromCache = false}) async {
    String cacheKey = "${_currentStudyId}_${Table.scheduled_surveys.name()}";
    CollectionReference? collectionReference = _firestoreManager.getEntitiesReference(
        [Table.users, Table.enrolled_studies, Table.scheduled_surveys],
        [_authManager.user!.id, _currentStudyId]);
    Query query = collectionReference!.where(ScheduledSurveyKey.schedule_type.name,
        isEqualTo: ScheduleType.scheduled.name);
    return await _firestoreManager.queryCollectionReference(query: query,
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