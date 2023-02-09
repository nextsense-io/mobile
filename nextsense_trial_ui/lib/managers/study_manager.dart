import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_storage_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:path_provider/path_provider.dart';

class StudyManager {
  static const String _studiesDir = 'studies';
  static const String _introDir = 'intro';

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('StudyManager');

  // Study definition.
  Study? _currentStudy;
  // Enrolled study state for this user.
  EnrolledStudy? _enrolledStudy;
  Directory? _appDocumentsRoot;
  List<IntroPageContent> introPageContents = [];

  DateTime? get currentStudyStartDate => _enrolledStudy?.getStartDate();
  DateTime? get currentStudyEndDate => _enrolledStudy?.getEndDate();
  String? get currentStudyId => _enrolledStudy?.id ?? null;
  Study? get currentStudy => _currentStudy;
  EnrolledStudy? get currentEnrolledStudy => _enrolledStudy;

  // List of days that will appear for current study
  List<StudyDay>? _days;

  List<StudyDay> get days => _days ?? [];

  List<ScheduledProtocol> scheduledProtocols = [];

  // Can be null if enrolled study isn't loaded at the moment
  bool? get studyInitialized => _enrolledStudy?.initialized;

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

  // Loads the study static information and generate the list of study days.
  Future<bool> loadCurrentStudy() async {
    // Load the study data.
    final user = _authManager.user!;

    final studyId = user.getValue(UserKey.current_study);
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

  Future<bool> loadScheduledProtocols() async {
    scheduledProtocols.clear();

    if (studyInitialized == null) {
      throw("study not initialized. cannot load scheduled protocols");
    }

    if (studyInitialized!) {
      // If study already initialized, return scheduled protocols from cache.
      _logger.log(Level.INFO, 'Loading scheduled protocols from cache');
      List<ScheduledProtocol>? protocols = await _loadScheduledProtocolsFromCache();
      if (protocols == null) {
        return false;
      }
      scheduledProtocols = protocols;
      _logger.log(Level.INFO, 'Loading ${scheduledProtocols.length} scheduled protocols');
    } else {
      _logger.log(Level.INFO, 'Creating scheduled protocols based on planned assessments');

      Stopwatch stopwatch = new Stopwatch()..start();
      List<PlannedAssessment>? assessments = await _loadPlannedAssessments();
      _logger.log(Level.INFO, "Load planned assessments complete in " +
          '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
      if (assessments == null) {
        return false;
      }

      final batchWriter = _firestoreManager.getFirebaseBatchWriter();
      for (var assessment in assessments) {
        if (assessment.protocol == null) {
          _logger.log(Level.WARNING, 'assessment protocol is null');
          continue;
        }
        final String time = assessment.startTimeStr.replaceAll(":", "_");

        for (StudyDay studyDay in assessment.days) {
          final String dayNumberStr = studyDay.dayNumber.toString().padLeft(3, '0');

          String scheduledProtocolKey = "${assessment.id}_day_${dayNumberStr}_time_$time";

          DocumentReference ref = _firestoreManager.getReference(
              [Table.users, Table.enrolled_studies, Table.scheduled_protocols],
              [_authManager.userCode!, currentStudy!.id, scheduledProtocolKey]);

          Map<String, dynamic> fields = {};

          fields[ScheduledProtocolKey.protocol.name] = assessment.reference;
          fields[ScheduledProtocolKey.sessions.name] = [];
          fields[ScheduledProtocolKey.status.name] = ProtocolState.not_started.name;
          fields[ScheduledProtocolKey.start_date.name] = studyDay.dateAsString;
          DateTime startDateTime = studyDay.date.add(
              Duration(hours: assessment.startTime.hour,
                  minutes: assessment.startTime.minute));
          fields[ScheduledProtocolKey.start_datetime.name] = startDateTime.toString();

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
        PlannedAssessment? plannedAssessment = assessments.firstWhereOrNull((assessment) =>
            entity.getValue(ScheduledProtocolKey.protocol) == assessment.reference);
        scheduledProtocols.add(ScheduledProtocol(entity, plannedAssessment!));
      }

      _logger.log(Level.INFO, "Scheduled protocols created in " +
          '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
    }

    return true;
  }

  Future<List<ScheduledProtocol>?> _loadScheduledProtocolsFromCache() async {
    List<FirebaseEntity>? scheduledProtocolEntities =
        await _queryScheduledProtocols(fromCache: true);
    if (scheduledProtocolEntities == null) {
      return null;
    }

    List<PlannedAssessment>? assessments = await _loadPlannedAssessments(fromCache: true);
    if (assessments == null) {
      return null;
    }

    List<ScheduledProtocol> result = [];
    for (FirebaseEntity entity in scheduledProtocolEntities) {
      final assessmentId = (entity.getValue(ScheduledProtocolKey.protocol) as DocumentReference).id;
      PlannedAssessment? plannedAssessment = assessments.firstWhereOrNull(
          (assessment) => assessmentId == assessment.reference.id);

      if (plannedAssessment == null) {
        _logger.log(Level.SEVERE, 'Assessment with id $assessmentId not found');
        continue;
      }

      final scheduledProtocol = ScheduledProtocol(entity, plannedAssessment);
      result.add(scheduledProtocol);
    }
    return result;
  }

  Future<ScheduledProtocol?> queryScheduledProtocol(String scheduledProtocolId) async {
    FirebaseEntity? scheduledProtocolEntity = await _firestoreManager.queryEntity(
        [Table.users, Table.enrolled_studies, Table.scheduled_protocols],
        [_authManager.userCode!, _currentStudy!.id, scheduledProtocolId]);
    if (scheduledProtocolEntity != null) {
      final assessmentId = (scheduledProtocolEntity.getValue(ScheduledProtocolKey.protocol)
          as DocumentReference).id;
      FirebaseEntity? plannedAssessmentEntity = await _firestoreManager.queryEntity(
          [Table.studies, Table.planned_assessments], [_currentStudy!.id, assessmentId]);
      if (plannedAssessmentEntity != null) {
        return ScheduledProtocol(scheduledProtocolEntity, PlannedAssessment(
            plannedAssessmentEntity, _enrolledStudy!.getStartDate()!,
            _enrolledStudy!.getEndDate()!));
      }
    }
    return null;
  }

  Future<List<FirebaseEntity>?> _queryScheduledProtocols(
      {bool fromCache = false}) async {
    return await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies, Table.scheduled_protocols],
        [_authManager.userCode!, _currentStudy!.id],
        fromCacheWithKey: fromCache ?
        "${_currentStudy!.id}_${Table.scheduled_protocols.name()}" : null);
  }

  Future<List<PlannedAssessment>?> _loadPlannedAssessments(
      {bool fromCache = false}) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_assessments], [_currentStudy!.id],
        fromCacheWithKey: fromCache ? Table.planned_assessments.name() : null);
    if (entities == null) {
      return null;
    }
    return entities.map((firebaseEntity) =>
            PlannedAssessment(firebaseEntity, currentStudyStartDate!, currentStudyEndDate!))
            .toList();
  }

  Future<List<PlannedSurvey>?> loadPlannedSurveys() async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_surveys], [_currentStudy!.id]);
    if (entities == null) {
      return null;
    }
    return entities
        .map((firebaseEntity) =>
        PlannedSurvey(firebaseEntity,
            currentStudyStartDate!,
            currentStudyEndDate!
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

  Future<bool> setStudyInitialized(bool initialized) async {
    if (initialized) {
      _logger.log(Level.INFO, "Mark current study as initialized");
    }
    _enrolledStudy!.setInitialized(initialized);
    return await _enrolledStudy!.save();
  }

  Future<bool> markEnrolledStudyShown() async {
    if (_enrolledStudy == null) {
      return false;
    }
    _enrolledStudy!.setIntroShown(true);
    return await _enrolledStudy!.save();
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