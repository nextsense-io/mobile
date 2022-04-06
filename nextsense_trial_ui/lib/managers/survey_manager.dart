import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/survey.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class SurveyManager {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyManager');

  final FirestoreManager _firestoreManager =
      getIt<FirestoreManager>();

  Future<List<Survey>> loadSurveys() async {
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.surveys], []
    );

    List<Survey> result = [];

    for (FirebaseEntity entity in entities) {
      final survey = Survey(entity);
      // TODO(alex): load multiple surveys async to speedup
      await survey.loadQuestions();
      result.add(survey);
    }

    return result;

  }


}