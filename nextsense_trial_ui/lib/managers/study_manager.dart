import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

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
    return true;
  }

  Future<List<ScheduledProtocol>> loadScheduledProtocols() async {
    List<PlannedAssessment> assesments = await _loadPlannedAssesments();
    List<ScheduledProtocol> result = [];
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

        result.add(scheduledProtocol);
      }
    }
    return result;
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

}