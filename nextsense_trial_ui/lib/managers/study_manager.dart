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
    List<PlannedAssessment> assesments = await _loadPlannedAssesments();
    for (var assesment in assesments) {
      if (assesment.protocol != null) {
        final String time = assesment.startTimeStr.replaceAll(":", "_");
        String scheduledProtocolKey =
            "day_${assesment.dayNumber}_time_${time}";
        final scheduledProtocol = ScheduledProtocol(
            await _firestoreManager.queryEntity(
                [Table.users, Table.scheduled_protocols],
                [_authManager.getUserCode()!, scheduledProtocolKey])
            , assesment);

        scheduledProtocol
            ..setValue(ScheduledProtocolKey.protocol, assesment.reference)
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
    return true;
  }

  Future<List<PlannedAssessment>> _loadPlannedAssesments() async {
    if (_currentStudy == null) {
      return Future.value([]);
    }
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_assessments], [_currentStudy!.id]);

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