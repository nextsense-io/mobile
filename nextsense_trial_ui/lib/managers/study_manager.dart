import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
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
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class StudyManager {

  final FirestoreManager _firestoreManager =
      GetIt.instance.get<FirestoreManager>();

  final CustomLogPrinter _logger = CustomLogPrinter('StudyManager');
  final AuthManager _authManager = getIt<AuthManager>();

  // Study definition.
  Study? _currentStudy;
  // Enrolled study state for this user.
  EnrolledStudy? _enrolledStudy;

  DateTime? get currentStudyStartDate => _enrolledStudy?.getStartDate();
  DateTime? get currentStudyEndDate => _enrolledStudy?.getEndDate();
  String? get currentStudyId => _enrolledStudy?.id ?? null;
  Study? get currentStudy => _currentStudy;

  // List of days that will appear for current study
  List<StudyDay>? _days;

  List<StudyDay> get days => _days ?? [];

  List<ScheduledProtocol> scheduledProtocols = [];

  bool get studyInitialized => _enrolledStudy!.initialized;

  // References today's study day
  // Has to be dynamic because next day can start while app is on
  StudyDay? get today {
    if (_days == null) {
      return null;
    }
    DateTime now = DateTime.now();
    return _days!.firstWhereOrNull((StudyDay day) => now.isSameDay(day.date));
  }

  Future<bool> loadEnrolledStudy(String user_id, String study_id) async {
    FirebaseEntity enrolledStudyEntity;
    try {
      enrolledStudyEntity = await _firestoreManager.queryEntity(
          [Table.users, Table.enrolled_studies], [user_id, study_id]);
    } catch(e) {
      _logger.log(Level.SEVERE,
          'Error when trying to load the enrolled study ${study_id}: ${e}');
      return false;
    }
    if (!enrolledStudyEntity.getDocumentSnapshot().exists) {
      _logger.log(Level.SEVERE,
          'Enrolled Study ${study_id} does not exist');
      return false;
    }
    _enrolledStudy = EnrolledStudy(enrolledStudyEntity);
    bool studyLoaded = await _loadCurrentStudy();
    if (!studyLoaded) {
      return false;
    }
    _createStudyDays();
    return true;
  }

  // Loads the study static information and generate the list of study days.
  Future<bool> _loadCurrentStudy() async {
    FirebaseEntity studyEntity;
    try {
      studyEntity = await _firestoreManager.queryEntity(
          [Table.studies], [currentStudyId!]);
    } catch(e) {
      _logger.log(Level.SEVERE,
          'Error when trying to load the study ${currentStudyId}: ${e}');
      return false;
    }
    if (!studyEntity.getDocumentSnapshot().exists) {
      _logger.log(Level.SEVERE,
          'Study ${_enrolledStudy!.id} does not exist');
      return false;
    }
    _currentStudy = Study(studyEntity);
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

  Future<bool> loadScheduledProtocols() async {
    scheduledProtocols.clear();

    if (studyInitialized) {
      // If study already initialized, return scheduled protocols from cache
      _logger.log(Level.INFO, 'Loading scheduled protocols from cache');
      scheduledProtocols = await _loadScheduledProtocolsFromCache();
      _logger.log(Level.INFO, 'Loading ${scheduledProtocols.length}'
          ' scheduled protocols');
    } else {
      _logger.log(Level.INFO,
          'Creating scheduled protocols based on planned assessments');

      Stopwatch stopwatch = new Stopwatch()..start();
      List<PlannedAssessment> assessments = await _loadPlannedAssessments();

      _logger.log(Level.INFO, "Load planned assessments complete in " +
          '${stopwatch.elapsedMicroseconds / 1000000.0} sec');

      final batchWriter = FirestoreBatchWriter();
      for (var assessment in assessments) {
        if (assessment.protocol == null) {
          _logger.log(Level.WARNING, 'assessment protocol is null');
          continue;
        }
        final String time = assessment.startTimeStr.replaceAll(":", "_");
        final String dayNumberStr = assessment.dayNumber
            .toString().padLeft(3, '0');

        String scheduledProtocolKey =
            "${assessment.id}_day_${dayNumberStr}_time_${time}";

        DocumentReference ref = _firestoreManager.getReference(
            [Table.users, Table.enrolled_studies, Table.scheduled_protocols],
            [_authManager.getUserCode()!, currentStudy!.id,
              scheduledProtocolKey]);

        Map<String, dynamic> fields = {};

        fields[ScheduledProtocolKey.protocol.name] = assessment.reference;
        fields[ScheduledProtocolKey.sessions.name] = [];
        fields[ScheduledProtocolKey.status.name] =
            ProtocolState.not_started.name;
        fields[ScheduledProtocolKey.start_date.name] =
            assessment.startDateAsString;
        fields[ScheduledProtocolKey.start_datetime.name] =
            assessment.startDateTimeAsString;

        batchWriter.add(ref, fields);
      }

      _logger.log(Level.INFO, "Commiting ${batchWriter.numberOfBatches} batches");

      await batchWriter.commitAll();

      // Make sure cache is up to date, need to query whole collection
      // Without this query undesired items can appear in cache
      List<FirebaseEntity> scheduledProtocolEntities =
          await _queryScheduledProtocols();

      for (var entity in scheduledProtocolEntities) {
        PlannedAssessment? plannedAssessment = assessments.firstWhereOrNull(
                (assessment) =>
            entity.getValue(ScheduledProtocolKey.protocol) ==
                assessment.reference);

        scheduledProtocols.add(ScheduledProtocol(entity, plannedAssessment!));
      }

      _logger.log(Level.INFO, "Scheduled protocols created in " +
          '${stopwatch.elapsedMicroseconds / 1000000.0} sec');
    }

    return true;
  }

  Future<List<ScheduledProtocol>> _loadScheduledProtocolsFromCache() async {
    List<FirebaseEntity> scheduledProtocolEntities =
        await _queryScheduledProtocols(fromCache: true);

    List<PlannedAssessment> assessments =
        await _loadPlannedAssessments(fromCache: true);
    List<ScheduledProtocol> result = [];

    for (FirebaseEntity entity in scheduledProtocolEntities) {
      final assessmentId = (entity.getValue(ScheduledProtocolKey.protocol)
          as DocumentReference).id;
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

  Future<List<FirebaseEntity>> _queryScheduledProtocols(
      {bool fromCache = false}) async {
    return await _firestoreManager.queryEntities(
        [Table.users, Table.enrolled_studies, Table.scheduled_protocols],
        [_authManager.userCode!, _currentStudy!.id],
        fromCacheWithKey: fromCache ?
        "${_currentStudy!.id}_${Table.scheduled_protocols.name()}" : null);
  }

  Future<List<PlannedAssessment>> _loadPlannedAssessments(
      {bool fromCache = false}) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_assessments], [_currentStudy!.id],
        fromCacheWithKey: fromCache ? Table.planned_assessments.name() : null);

    return entities
        .map((firebaseEntity) =>
            PlannedAssessment(firebaseEntity, currentStudyStartDate!))
        .toList();
  }

  Future<List<PlannedSurvey>> loadPlannedSurveys() async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_surveys], [_currentStudy!.id]);

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

  Future setStudyInitialized(bool initialized) async {
    if (initialized) {
      _logger.log(Level.INFO, "Mark current study as initialized");
    }
    await _enrolledStudy!
      ..setInitialized(initialized)
      ..save();
  }
}