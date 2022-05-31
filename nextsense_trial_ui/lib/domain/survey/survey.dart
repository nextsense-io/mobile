import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum SurveyKey {
  duration_minutes,
  name,
  intro_text,
  intro_image
}

enum SurveyQuestionKey {
  type,
  text,
  choices,
  optional
}

enum SurveyQuestionType {
  yesno,
  range,
  number,
  choices,
  text,
  time,
  unknown
}

//TODO(alex): move this to database at some point
enum SurveyQuestionSpecialChoices {
  phq9, // Patient Health Questionnaire (PHQ-9)
  gad7, // General Anxiety Disorder (GAD-7)
  sqs, // Sleep Quality Scale
  unknown
}

enum SurveyState {
  not_started,
  skipped,
  completed,
  unknown
}

enum SurveyPeriod {
  specific_day,
  daily,
  weekly,
  unknown
}

class SurveyQuestionChoice {
  final String value;
  final String text;
  const SurveyQuestionChoice(this.value, this.text);
}

class SurveyQuestion extends FirebaseEntity<SurveyQuestionKey>{

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyQuestion');

  List<SurveyQuestionChoice> choices = [];

  SurveyQuestionType get type =>
      surveyQuestionTypeFromString(typeString);

  String get typeString => getValue(SurveyQuestionKey.type);

  String get text => getValue(SurveyQuestionKey.text);

  // Optional question can be skipped
  bool get optional => getValue(SurveyQuestionKey.optional) ?? false;

  SurveyQuestion(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot()) {
    dynamic choicesValue = getValue(SurveyQuestionKey.choices);

    if (![SurveyQuestionType.range, SurveyQuestionType.choices].contains(
        type)) {
      // For other types we don't need to specify choices
      return;
    }
    if (choicesValue is List) {
      // List of value/text items
      choices = choicesValue
          .map((item) => SurveyQuestionChoice(item['value'], item['text']))
          .toList();
    } else if (choicesValue is String) {
      if (type == SurveyQuestionType.range) {
        // Range of values
        // Example: '1-4' transforms into list of 1,2,3,4
        final int min,max;
        try {
          List<String> minMaxStr = choicesValue.split("-");
          min = int.parse(minMaxStr[0]);
          max = int.parse(minMaxStr[1]);
        } catch (e) {
          _logger.log(Level.WARNING,
              'Failed to parse choices: ${choicesValue}');
          return;
        }
        for (int choice = min; choice <= max; choice++) {
          choices
              .add(SurveyQuestionChoice(choice.toString(), choice.toString()));
        }
        return;
      }
      choices = _getSpecialChoices(
              surveyQuestionSpecialChoicesFromString(choicesValue));
    } else {
      _logger.log(
          Level.WARNING, 'Invalid value for choices "$choicesValue"');
    }
  }

  // Get predefined list of 'special' choices for certain ambulatory
  // surveys
  List<SurveyQuestionChoice> _getSpecialChoices(
      SurveyQuestionSpecialChoices specialChoices) {
    switch (specialChoices) {
      case SurveyQuestionSpecialChoices.phq9:
        return [
          SurveyQuestionChoice("0", "Not at all"),
          SurveyQuestionChoice("1", "Several days"),
          SurveyQuestionChoice("2", "More than half the days"),
          SurveyQuestionChoice("3", "Nearly every day"),
        ];
      case SurveyQuestionSpecialChoices.gad7:
        return [
          SurveyQuestionChoice("0", "Not at all sure"),
          SurveyQuestionChoice("1", "Several days"),
          SurveyQuestionChoice("2", "Over half the days"),
          SurveyQuestionChoice("3", "Nearly every day"),
        ];
      case SurveyQuestionSpecialChoices.sqs:
        return [
          SurveyQuestionChoice("0", "Rarely"),
          SurveyQuestionChoice("1", "Sometimes"),
          SurveyQuestionChoice("2", "Often"),
          SurveyQuestionChoice("3", "Almost always"),
        ];
      case SurveyQuestionSpecialChoices.unknown:
        _logger.log(
            Level.WARNING, 'Unknown set of special choices "$specialChoices"');
        break;
    }
    return [];
  }
}

class Survey extends FirebaseEntity<SurveyKey> {

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  List<SurveyQuestion> questions = [];

  String get name => getValue(SurveyKey.name) ?? "";

  String get introText => getValue(SurveyKey.intro_text) ?? "";

  Duration get duration => Duration(minutes: getValue(SurveyKey.duration_minutes) ?? 0);

  Survey(FirebaseEntity firebaseEntity)
      : super(firebaseEntity.getDocumentSnapshot());

  Future<bool> loadQuestions({bool fromCache = false}) async {
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.surveys, Table.questions], [this.id],
        fromCacheWithKey: fromCache ? "survey_${this.id}_questions" : null
    );

    if (entities == null) {
      return false;
    }
    questions = entities.map((firebaseEntity) =>
        SurveyQuestion(firebaseEntity))
        .toList();
    return true;
  }

}

SurveyQuestionType surveyQuestionTypeFromString(String typeStr) {
  return SurveyQuestionType.values.firstWhere(
      (element) => element.name == typeStr,
      orElse: () => SurveyQuestionType.unknown);
}

// TODO(alex): make generics for those kind of functions
SurveyQuestionSpecialChoices surveyQuestionSpecialChoicesFromString(String choicesStr) {
  return SurveyQuestionSpecialChoices.values.firstWhere(
          (element) => element.name == choicesStr,
      orElse: () => SurveyQuestionSpecialChoices.unknown);
}

SurveyState surveyStateFromString(String surveyStateStr) {
  return SurveyState.values.firstWhere(
      (element) => element.name == surveyStateStr,
      orElse: () => SurveyState.unknown);
}

SurveyPeriod surveyPeriodFromString(String surveyPeriodStr) {
  return SurveyPeriod.values.firstWhere(
          (element) => element.name == surveyPeriodStr,
      orElse: () => SurveyPeriod.unknown);
}