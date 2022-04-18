import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

class StudyManager {

  final FirestoreManager _firestoreManager =
      GetIt.instance.get<FirestoreManager>();

  final CustomLogPrinter _logger = CustomLogPrinter('StudyManager');
  final AuthManager _authManager = getIt<AuthManager>();

  Study? _currentStudy;

  late DateTime currentStudyStartDate;
  late DateTime currentStudyEndDate;

  String? get currentStudyId => _currentStudy?.id ?? null;

  Study? get currentStudy => _currentStudy;

  // List of days that will appear for current study
  List<StudyDay>? _days;

  List<StudyDay> get days => _days ?? [];

  List<ScheduledProtocol> scheduledProtocols = [];

  bool get studyInitialized => _authManager.user!.studyInitialized;

  // References today's study day
  // Has to be dynamic because next day can start while app is on
  StudyDay? get today {
    if (_days == null) {
      return null;
    }
    DateTime now = DateTime.now();
    return _days!.firstWhere((StudyDay day) => now.isSameDay(day.date));
  }

  Future<bool> loadCurrentStudy(String study_id, DateTime startDate, DateTime endDate) async {
    FirebaseEntity studyEntity;
    try {
      studyEntity = await _firestoreManager.queryEntity(
          [Table.studies], [study_id]);
    } catch(e) {
      _logger.log(Level.SEVERE,
          'Error when trying to load the study ${study_id}: ${e}');
      return false;
    }
    if (!studyEntity.getDocumentSnapshot().exists) {
      _logger.log(Level.SEVERE,
          'Study ${study_id} does not exist');
      return false;
    }
    _currentStudy = Study(studyEntity);
    currentStudyStartDate = startDate;
    currentStudyEndDate = endDate;

    // Create list of study days
    final int studyDays = currentStudy?.getDurationDays() ?? 0;
    _days = List<StudyDay>.generate(studyDays, (i) {
      DateTime dayDate = currentStudyStartDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final studyDay = StudyDay(dayDate, dayNumber);
      return studyDay;
    });
    return true;
  }

  Future<bool> loadScheduledProtocols() async {
    scheduledProtocols.clear();

    if (studyInitialized) {
      // If study already initialized, return scheduled protocols from cache
      _logger.log(Level.WARNING, 'Loading scheduled protocols from cache');
      scheduledProtocols = await _loadScheduledProtocolsFromCache();
    } else {

      _logger.log(Level.WARNING,
          'Creating scheduled protocols based on planned assessments');

      List<PlannedAssessment> assessments = await _loadPlannedAssessments();
      for (var assessment in assessments) {
        if (assessment.protocol != null) {
          final String time = assessment.startTimeStr.replaceAll(":", "_");
          String scheduledProtocolKey =
              "day_${assessment.dayNumber}_time_${time}";
          final scheduledProtocol = ScheduledProtocol(
              await _firestoreManager.queryEntity(
                  [Table.users, Table.scheduled_protocols],
                  [_authManager.getUserCode()!, scheduledProtocolKey]),
              assessment);

          scheduledProtocol
            ..setValue(ScheduledProtocolKey.protocol, assessment.reference)
            ..setValue(ScheduledProtocolKey.sessions, []);

          // Initial status for protocol is not_started
          if (scheduledProtocol.getValue(ScheduledProtocolKey.status) == null) {
            scheduledProtocol.setValue(ScheduledProtocolKey.status,
                ProtocolState.not_started.name);
          }
          scheduledProtocol.save();

          scheduledProtocols.add(scheduledProtocol);
        }
      }
    }
    return true;
  }

  Future<List<ScheduledProtocol>> _loadScheduledProtocolsFromCache() async {
    List<FirebaseEntity> entities =
        await _queryScheduledProtocols(fromCache: true);

    List<PlannedAssessment> assessments =
        await _loadPlannedAssessments(fromCache: true);
    List<ScheduledProtocol> result = [];

    for (FirebaseEntity entity in entities) {
      final assessmentId = (entity.getValue(ScheduledProtocolKey.protocol)
      as DocumentReference).id;
      PlannedAssessment? assessment = assessments.firstWhereOrNull(
          (assesment) => assessmentId == assesment.reference.id);

      if (assessment == null) {
        _logger.log(Level.SEVERE, 'Assessment with id $assessmentId not found');
        continue;
      }

      final scheduledProtocol = ScheduledProtocol(entity, assessment);
      result.add(scheduledProtocol);
    }

    return result;

  }

  Future<List<FirebaseEntity>> _queryScheduledProtocols(
      {bool fromCache = false}) async {
    return await _firestoreManager.queryEntities(
        [Table.users, Table.scheduled_protocols],
        [_authManager.getUserCode()!],
        fromCacheWithKey: fromCache ? "scheduled_protocols" : null);
  }

  Future<List<PlannedAssessment>> _loadPlannedAssessments(
      {bool fromCache = false}) async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_assessments], [_currentStudy!.id],
        fromCacheWithKey: fromCache ? "planned_assessments" : null);

    return entities
        .map((firebaseEntity) =>
            PlannedAssessment(firebaseEntity, currentStudyStartDate))
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
            currentStudyStartDate,
            currentStudyEndDate
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
    await _authManager.user!
      ..setStudyInitialized(initialized)
      ..save();
  }

}