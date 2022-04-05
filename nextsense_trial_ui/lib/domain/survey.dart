import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

enum SurveyKey {
  name,
  intro_text,
  intro_image
}

enum SurveyQuestionKey {
  type,
  text
}

enum SurveyQuestionType {
  yesno,
  range,
  number,
  text
}

class Question extends FirebaseEntity<SurveyQuestionKey>{
  late SurveyQuestionType type;
  late String text;

  Question(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot());

}

class Survey extends FirebaseEntity<SurveyKey> {

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  List<Question>? questions;

  String get name => getValue(SurveyKey.name) ?? "";

  Survey(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot());

  Future loadQuestions() async {
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.surveys, Table.questions], [this.id]);

    questions = entities.map((firebaseEntity) =>
        Question(firebaseEntity))
        .toList();
  }

}