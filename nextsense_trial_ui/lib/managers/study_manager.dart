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

  Future<List<Assessment>> loadAssesments() async {
    if (_currentStudy == null) return Future.value([]);
    var collection = await FirebaseFirestore.instance
        .collection(Table.studies.name())
        .doc(_currentStudy!.id)
        .collection(Table.planned_assessments.name()).get();

    final List<Assessment> result = [];
    for (var doc in collection.docs) {
      final assessment = Assessment(FirebaseEntity(doc), currentStudyStartDate);
      // Skip creation of assessment in case of some error and
      // protocol is not set
      if (assessment.protocol != null) {
        result.add(assessment);
      }
    }
    return result;
  }

  String? getCurrentStudyId() {
    return _currentStudy?.id ?? null;
  }

  Study? getCurrentStudy() {
    return _currentStudy;
  }

  //DateTime
}