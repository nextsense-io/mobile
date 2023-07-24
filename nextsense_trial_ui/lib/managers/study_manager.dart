import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/planned_session.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/scheduled_session.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_storage_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:path_provider/path_provider.dart';

class StudyManager {
  static const String _studiesDir = 'studies';
  static const String _introDir = 'intro';

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final Preferences _preferences = getIt<Preferences>();
  final CustomLogPrinter _logger = CustomLogPrinter('StudyManager');

  // Study definition.
  Study? _currentStudy;
  // Enrolled study state for this user.
  EnrolledStudy? _enrolledStudy;
  Directory? _appDocumentsRoot;
  List<IntroPageContent> introPageContents = [];
  // List of days that will appear for current study
  List<StudyDay>? _days;
  List<PlannedSession>? _plannedSessions;
  List<PlannedSession> _allowedAdhocProtocols = [];
  List<ScheduledSession> _scheduledSessions = [];
  List<PlannedMedication> _plannedMedications = [];

  List<ScheduledSession> get scheduledSessions => _scheduledSessions;
  List<PlannedSession> get allowedAdhocProtocols => _allowedAdhocProtocols;
  List<PlannedMedication> get plannedMedications => _plannedMedications;
  DateTime? get currentStudyStartDate => _enrolledStudy?.getStartDate();
  DateTime? get currentStudyEndDate => _enrolledStudy?.getEndDate();
  String? get currentStudyId => _enrolledStudy?.id ?? null;
  Study? get currentStudy => _currentStudy;
  EnrolledStudy? get currentEnrolledStudy => _enrolledStudy;
  List<StudyDay> get days => _days ?? [];
  // Can be null if enrolled study isn't loaded at the moment.
  bool? get studyScheduled => _enrolledStudy?.isScheduled;
  // References today's study day.
  // Has to be dynamic because next day can start while app is on.
  StudyDay? get today {
    if (_days == null) {
      return null;
    }
    DateTime now = DateTime.now();
    StudyDay? today = _days!.firstWhereOrNull((StudyDay day) => now.isSameDay(day.date));
    _logger.log(Level.INFO, 'Study day: ${today?.dayNumber ?? 'Null'}');
    return _days!.firstWhereOrNull((StudyDay day) => now.isSameDay(day.date));
  }

  Future<Study?> getStudy(String studyId) async {
    if (_currentStudy != null && _currentStudy!.id == studyId) {
      return _currentStudy!;
    }
    FirebaseEntity? studyEntity = await _firestoreManager.queryEntity(
        [Table.studies], [studyId]);
    if (studyEntity == null) {
      return null;
    }
    return Study(studyEntity);
  }

  // Get the enrolled studies from the database. This data could change at anytime so always get it
  // from the database and not from a cache.
  Future<List<EnrolledStudy>?> getEnrolledStudies(String userId) async {
    List<FirebaseEntity>? enrolledStudiesEntities;
    enrolledStudiesEntities = await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies], [userId]);
    if (enrolledStudiesEntities == null) {
      return null;
    }
    if (enrolledStudiesEntities.isEmpty) {
      _logger.log(Level.SEVERE, 'No enrolled studies for $userId');
      return [];
    }
    return enrolledStudiesEntities.map((entity) => EnrolledStudy(entity)).toList();
  }

  // Loads the study static information and generate the list of study days.
  Future<bool> loadCurrentStudy() async {
    // Load the study data.
    final user = _authManager.user!;

    final studyId = user.getValue(UserKey.current_study_id);
    if (studyId == null) {
      throw("'current_study' is not set for user");
    }

    // We start with loading enrolled study, which holds the current study state.
    bool enrolledStudyLoaded = await _loadEnrolledStudy(user.id, studyId);
    if (!enrolledStudyLoaded) {
      _logger.log(Level.SEVERE, 'Error when trying to load the enrolled study $studyId');
      return false;
    }

    // Then we need to load the current study.
    FirebaseEntity? studyEntity = await _firestoreManager.queryEntity(
          [Table.studies], [currentStudyId!]);
    if (studyEntity == null) {
      return false;
    }
    if (!studyEntity.getDocumentSnapshot().exists) {
      _logger.log(Level.SEVERE, 'Study ${_enrolledStudy!.id} does not exist');
      return false;
    }
    _currentStudy = Study(studyEntity);
    await _createStudyDays();
    await _initAppRootDir();
    await _cacheStudyImages();
    return true;
  }

  Future<bool> loadScheduledProtocols() async {
    scheduledSessions.clear();
    _allowedAdhocProtocols.clear();

    if (studyScheduled == null) {
      throw("study not initialized. cannot load scheduled protocols");
    }

    bool fromCache = _preferences.getBool(PreferenceKey.studyDataCached);
    _plannedSessions = await _loadPlannedSessions(fromCache: fromCache && studyScheduled!);
    if (_plannedSessions == null) {
      return false;
    }
    // Initialize allowed adhoc protocols.
    for (var plannedSession in _plannedSessions!) {
      if (plannedSession.scheduleType == ScheduleType.adhoc) {
        _allowedAdhocProtocols.add(plannedSession);
      }
    }

    if (studyScheduled!) {
      // If study already scheduled, return scheduled sessions from cache if present.
      _logger.log(Level.INFO, 'Loading scheduled sessions from cache? $fromCache');
      List<ScheduledSession>? scheduledSessions = await _loadScheduledSessions(fromCache);
      if (scheduledSessions == null) {
        return false;
      }
      _scheduledSessions = scheduledSessions;
      _logger.log(Level.INFO, 'Loaded ${scheduledSessions.length} scheduled sessions');
    } else {
      _logger.log(Level.INFO, 'Creating scheduled sessions based on planned sessions');
      Stopwatch stopwatch = new Stopwatch()..start();
      final batchWriter = _firestoreManager.getFirebaseBatchWriter();
      for (var plannedSession in _plannedSessions!) {
        if (plannedSession.protocol == null) {
          _logger.log(Level.WARNING, 'assessment protocol is null');
          continue;
        }
        if (plannedSession.scheduleType != ScheduleType.scheduled) {
          continue;
        }
        for (StudyDay studyDay in plannedSession.days ?? []) {
          DocumentReference ref = await _firestoreManager.addAutoIdReference(
              [Table.users, Table.enrolled_studies, Table.scheduled_sessions],
              [_authManager.user!.id, currentStudy!.id]);

          Map<String, dynamic> fields = {};

          fields[ScheduledSessionKey.planned_session_id.name] = plannedSession.id;
          fields[ScheduledSessionKey.schedule_type.name] = plannedSession.scheduleType.name;
          fields[ScheduledSessionKey.session_ids.name] = [];
          fields[ScheduledSessionKey.status.name] = ProtocolState.not_started.name;
          fields[ScheduledSessionKey.start_date.name] = studyDay.dateAsString;
          DateTime startDateTime = studyDay.date.add(
              Duration(hours: plannedSession.startTime!.hour,
                  minutes: plannedSession.startTime!.minute));
          fields[ScheduledSessionKey.start_datetime.name] = startDateTime.toString();

          batchWriter.add(ref, fields);
        }
      }

      _logger.log(Level.INFO, "Committing ${batchWriter.numberOfBatches} batches");

      bool success = await batchWriter.commitAll();
      if (!success) {
        return false;
      }

      // Need to query the whole collection to make sure the cache is up to date.
      // Without this query undesired items can appear in the cache.
      List<FirebaseEntity>? scheduledProtocolEntities = await _queryScheduledProtocols();
      if (scheduledProtocolEntities == null) {
        return false;
      }

      for (var entity in scheduledProtocolEntities) {
        PlannedSession? plannedSession = _plannedSessions!.firstWhereOrNull((assessment) =>
            entity.getValue(ScheduledSessionKey.planned_session_id) == assessment.id);
        _scheduledSessions.add(ScheduledSession(entity, plannedSession!));
      }

      _logger.log(Level.INFO, "Scheduled sessions created in " +
          '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
      stopwatch.stop();
    }

    return true;
  }

  PlannedSession? getPlannedSessionById(String plannedSessionId) {
    return _plannedSessions?.firstWhereOrNull((plannedSession) =>
        plannedSession.id == plannedSessionId) ?? null;
  }

  Future<ScheduledSession?> scheduleSessionTrigger(PlannedSession triggerPlannedSession) async {
    if (triggerPlannedSession.triggersConditionalSessionId == null) {
      _logger.log(Level.WARNING, 'triggered planned session id is null');
      return null;
    }
    PlannedSession? triggeredPlannedSession = getPlannedSessionById(
        triggerPlannedSession.triggersConditionalSessionId!);
    if (triggeredPlannedSession == null) {
      _logger.log(Level.WARNING, 'triggered planned session '
          '${triggerPlannedSession.triggersConditionalSessionId} not found');
      return null;
    }

    FirebaseEntity entity = await _firestoreManager.addAutoIdEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_sessions],
        [_authManager.user!.id, currentStudy!.id]);

    ScheduledSession scheduledSession = ScheduledSession.fromSessionTrigger(
        entity, plannedSession: triggeredPlannedSession, triggeredBy: triggerPlannedSession.id);
    await scheduledSession.save();
    return scheduledSession;
  }

  Future<ScheduledSession?> queryScheduledProtocol(String scheduledProtocolId) async {
    FirebaseEntity? scheduledProtocolEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_sessions],
        [_authManager.user!.id, _currentStudy!.id, scheduledProtocolId]);
    if (scheduledProtocolEntity != null) {
      final assessmentId = (scheduledProtocolEntity.getValue(ScheduledSessionKey.planned_session_id)
          as DocumentReference).id;
      FirebaseEntity? plannedAssessmentEntity = await _firestoreManager.queryEntity(
          [Table.studies, Table.planned_sessions], [_currentStudy!.id, assessmentId]);
      if (plannedAssessmentEntity != null) {
        return ScheduledSession(scheduledProtocolEntity, PlannedSession(
            plannedAssessmentEntity, _enrolledStudy!.getStartDate()!,
            _enrolledStudy!.getEndDate()!));
      }
    }
    return null;
  }

  Future<List<PlannedSurvey>?> loadPlannedSurveys(bool fromCache) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_surveys], [_currentStudy!.id], fromCacheWithKey: fromCache ?
        "${_currentStudy!.id}_${Table.planned_surveys.name()}" : null);
    if (entities == null) {
      return null;
    }
    return entities
        .map((firebaseEntity) =>
        PlannedSurvey(firebaseEntity,
            studyStartDate: currentStudyStartDate,
            studyEndDate: currentStudyEndDate
        ))
        .toList();
  }

  Future<List<PlannedMedication>?> loadPlannedMedications(bool fromCache) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_medications], [_currentStudy!.id],
        fromCacheWithKey: fromCache ? "${_currentStudy!.id}_${Table.planned_medications.name()}" :
        null);
    if (entities == null) {
      return null;
    }
    return entities
        .map((firebaseEntity) =>
        PlannedMedication(firebaseEntity,
            studyStartDate: currentStudyStartDate!,
            studyEndDate: currentStudyEndDate!
        ))
        .toList();
  }

  StudyDay? getStudyDayByNumber(int dayNumber) {
    return _days?.firstWhereOrNull(
            (studyDay) => studyDay.dayNumber == dayNumber);
  }

  Duration getStudyLength() {
    if (_enrolledStudy == null || _enrolledStudy!.getStartDate() == null ||
        _enrolledStudy!.getEndDate() == null) {
      return Duration(days: 0);
    }
    return _enrolledStudy!.getEndDate()!.dateNoTime.difference(
        _enrolledStudy!.getStartDate()!.dateNoTime);
  }

  bool isStudyStarted() {
    if (currentStudyStartDate == null) {
      return false;
    }
    return DateTime.now().isAfter(currentStudyStartDate!);
  }

  bool isStudyFinished() {
    if (currentStudyEndDate == null) {
      return false;
    }
    return DateTime.now().isAfter(currentStudyEndDate!);
  }

  Future<bool> setStudyScheduled(bool scheduled) async {
    if (scheduled) {
      _logger.log(Level.INFO, "Mark current study as scheduled");
    }
    _enrolledStudy!.setIsScheduled(scheduled);
    _preferences.setBool(PreferenceKey.studyDataCached, scheduled);
    return await _enrolledStudy!.save();
  }

  Future<bool> markEnrolledStudyShown() async {
    if (_enrolledStudy == null) {
      return false;
    }
    _enrolledStudy!.setShowIntro(false);
    return await _enrolledStudy!.save();
  }


  Future<List<ScheduledSession>?> _loadScheduledSessions(bool fromCache) async {
    List<FirebaseEntity>? scheduledSessionEntities =
        await _queryScheduledProtocols(fromCache: fromCache);
    if (scheduledSessionEntities == null) {
      return null;
    }

    List<PlannedSession>? plannedSessions = await _loadPlannedSessions(fromCache: fromCache);
    if (plannedSessions == null) {
      return null;
    }

    List<ScheduledSession> scheduledSessions = [];
    for (FirebaseEntity entity in scheduledSessionEntities) {
      final plannedSessionId = entity.getValue(ScheduledSessionKey.planned_session_id);
      PlannedSession? plannedSession = plannedSessions.firstWhereOrNull(
          (plannedSessionCandidate) => plannedSessionId == plannedSessionCandidate.id);

      if (plannedSession == null) {
        _logger.log(Level.SEVERE, 'Planned session with id $plannedSessionId not found');
        continue;
      }

      final scheduledSession = ScheduledSession(entity, plannedSession);
      scheduledSessions.add(scheduledSession);
    }
    return scheduledSessions;
  }

  Future<List<FirebaseEntity>?> _queryScheduledProtocols({bool fromCache = false}) async {
    return await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies, Table.scheduled_sessions],
        [_authManager.user!.id, _currentStudy!.id],
        fromCacheWithKey: fromCache ?
        "${_currentStudy!.id}_${Table.scheduled_sessions.name()}" : null);
  }

  Future<List<PlannedSession>?> _loadPlannedSessions({bool fromCache = false}) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_sessions], [_currentStudy!.id],
        fromCacheWithKey: fromCache ? Table.planned_sessions.name() : null);
    if (entities == null) {
      return null;
    }
    return entities.map((firebaseEntity) =>
        PlannedSession(firebaseEntity, currentStudyStartDate!, currentStudyEndDate!))
        .toList();
  }

  // Loads EnrolledStudy entity which holds state of current study
  Future<bool> _loadEnrolledStudy(String userId, String studyId) async {
    FirebaseEntity? enrolledStudyEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.enrolled_studies], [userId, studyId]);
    if (enrolledStudyEntity == null) {
      return false;
    }
    if (!enrolledStudyEntity.getDocumentSnapshot().exists) {
      _logger.log(Level.SEVERE, 'Enrolled Study $studyId does not exist');
      return false;
    }
    _enrolledStudy = EnrolledStudy(enrolledStudyEntity);
    return true;
  }

  // Create list of study days
  Future _createStudyDays() async {
    final int studyDays = currentStudy?.getDurationDays() ?? 0;
    DateTime studyDayStartDate = currentStudyStartDate!;
    _days = List<StudyDay>.generate(studyDays, (i) {
      DateTime dayDate = studyDayStartDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final studyDay = StudyDay(dayDate, dayNumber);
      return studyDay;
    });
  }

  // Download the study introduction images from Firebase Storage and cache them locally.
  Future _cacheStudyImages() async {
    introPageContents = currentStudy!.getIntroPageContents();
    for (IntroPageContent introPageContent in introPageContents) {
      String fileName = introPageContent.imageGoogleStorageUrl.split('/').last;
      _getIntroDir().createSync(recursive: true);
      File localFile = File(_getIntroDir().absolute.path + '/' + fileName);
      if (localFile.existsSync()) {
        // Already cached, no need to download again.
        introPageContent.localCachedImage = localFile;
        continue;
      }
      // Don't check if actually downloaded, not critical, will be tried again next time.
      await _firebaseStorageManager.downloadFile(introPageContent.imageGoogleStorageUrl, localFile);
      introPageContent.localCachedImage = localFile;
    }
  }

  Future _initAppRootDir() async {
    if (_appDocumentsRoot == null) {
      _appDocumentsRoot = await getApplicationDocumentsDirectory();
    }
  }

  Directory _getStudyDir() {
    return Directory("${_appDocumentsRoot!.absolute.path}/$_studiesDir/${_currentStudy!.id}");
  }

  Directory _getIntroDir() {
    return Directory("${_getStudyDir().absolute.path}/$_introDir");
  }
}