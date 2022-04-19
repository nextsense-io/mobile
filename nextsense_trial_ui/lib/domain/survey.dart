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
  text,
  choices
}

enum SurveyQuestionType {
  yesno,
  range,
  number,
  choices,
  text,
  unknown
}

class Question extends FirebaseEntity<SurveyQuestionKey>{

  SurveyQuestionType get type =>
      surveyQuestionTypeFromString(typeString);

  String get typeString => getValue(SurveyQuestionKey.type);

  String get text => getValue(SurveyQuestionKey.text);

  dynamic get choices => getValue(SurveyQuestionKey.choices);

  Question(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot());

}

class Survey extends FirebaseEntity<SurveyKey> {

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  List<Question> questions = [];

  String get name => getValue(SurveyKey.name) ?? "";

  Survey(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot());

  Future loadQuestions() async {
    List<FirebaseEntity> entities = await _firestoreManager.queryEntities(
        [Table.surveys, Table.questions], [this.id]);

    //print('[TODO] Survey.loadQuestions $entities');

    questions = entities.map((firebaseEntity) =>
        Question(firebaseEntity))
        .toList();
  }

}

SurveyQuestionType surveyQuestionTypeFromString(String typeStr) {
  return SurveyQuestionType.values.firstWhere((element) => element.name == typeStr,
      orElse: () => SurveyQuestionType.unknown);
}