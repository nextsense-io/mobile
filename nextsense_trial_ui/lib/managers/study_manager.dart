import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class StudyManager {

  final FirestoreManager _firestoreManager =
      GetIt.instance.get<FirestoreManager>();

  final CustomLogPrinter _logger = CustomLogPrinter('StudyManager');

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
      return false;
    }
    _currentStudy = Study(studyEntity);
    currentStudyStartDate = startDate;
    currentStudyEndDate = endDate;
    return true;
  }

  Future<List<PlannedAssessment>> loadPlannedAssesments() async {
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