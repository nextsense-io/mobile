import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
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
        String scheduled_protocol_key =
            "day_${assesment.dayNumber}_time_${time}";
        final scheduledProtocol = ScheduledProtocol(
            await _firestoreManager.queryEntity(
                [Table.users, Table.scheduled_protocols],
                [_authManager.getUserCode()!, scheduled_protocol_key])
            , assesment);


        scheduledProtocol
            ..setValue(ScheduledProtocolKey.protocol, assesment.reference)
            ..setValue(ScheduledProtocolKey.sessions, []);

        // Initial status for protocol is not_started
        if (scheduledProtocol.getValue(ScheduledProtocolKey.status) == null) {
          scheduledProtocol.setValue(ScheduledProtocolKey.status,
              ProtocolState.not_started.name);
        }
        _firestoreManager.persistEntity(scheduledProtocol);

        result.add(scheduledProtocol);
      }
    }
    return result;
    //final int studyDays = _currentStudy?.getDurationDays() ?? 0;

    /*_days = List<DateTime>.generate(studyDays, (i) =>
        _studyManager.currentStudyStartDate.add(Duration(days: i)));*/
  }

  Future<List<PlannedAssessment>> _loadPlannedAssesments() async {
    if (_currentStudy == null) return Future.value([]);
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.studies, Table.planned_assessments],
        [_currentStudy!.id]
    );

    return entities.map((firebaseEntity) =>
        PlannedAssessment(firebaseEntity, currentStudyStartDate))
        .toList();
  }


  String? getCurrentStudyId() {
    return _currentStudy?.id ?? null;
  }

  Study? getCurrentStudy() {
    return _currentStudy;
  }
}