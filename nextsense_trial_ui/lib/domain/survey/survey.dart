import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/survey/condition.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum SurveyKey {
  abbreviation,
  duration_minutes,
  intro_text,
  intro_image_url,
  name;

  factory SurveyKey.fromString(String key) {
    return SurveyKey.values.firstWhere((e) => e.toString() == 'SurveyKey.$key');
  }
}

enum SurveyQuestionKey {
  choices,  // Possible choices for choices and range types
  conditions,  // Conditions for this question to appear
  hint,  // hint shown for text types
  text,  // Question prompt at the top
  type,  // type of question, see `SurveyQuestionType`
  optional,  // If the question is optional
  position,  // Index of the question in the survey
  range_min,  // Minimum value for range type
  range_max;  // Maximum value for range type

  factory SurveyQuestionKey.fromString(String key) {
    return SurveyQuestionKey.values.firstWhere((e) => e.toString() == 'SurveyQuestionKey.$key');
  }
}

enum SurveyQuestionType {
  yesno,  // Yes or No buttons
  range,  // Select between values
  number,  // Valid number selector
  choices,  // List of choices buttons
  text,  // Free text
  time,  // DateTime entry
  unknown;

  factory SurveyQuestionType.fromString(String key) {
    return SurveyQuestionType.values.firstWhere((e) => e.toString() == 'SurveyQuestionType.$key');
  }
}

enum SurveyYesNoChoices {
  yes,
  no;

  factory SurveyYesNoChoices.fromString(String key) {
    return SurveyYesNoChoices.values.firstWhere((e) => e.toString() == 'SurveyYesNoChoices.$key');
  }
}

//TODO(alex): move this to database at some point
enum SurveyQuestionSpecialChoices {
  phq9,  // Patient Health Questionnaire (PHQ-9)
  gad7,  // General Anxiety Disorder (GAD-7)
  sqs,  // Sleep Quality Scale
  panas_sf,  // Positive and Negative Affect Schedule
  unknown;

  factory SurveyQuestionSpecialChoices.fromString(String key) {
    return SurveyQuestionSpecialChoices.values.firstWhere(
            (e) => e.toString() == 'SurveyQuestionSpecialChoices.$key',
        orElse: () => SurveyQuestionSpecialChoices.unknown);
  }
}

enum SurveyState {
  not_started,
  started,
  partially_completed,
  skipped,
  completed,
  unknown;

  factory SurveyState.fromString(String key) {
    return SurveyState.values.firstWhere((e) => e.toString() == 'SurveyState.$key');
  }
}

class SurveyQuestionChoice {
  final String value;
  final String text;
  const SurveyQuestionChoice(this.value, this.text);
}

class SurveyQuestion extends FirebaseEntity<SurveyQuestionKey>{

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyQuestion');

  List<SurveyQuestionChoice> choices = [];
  Conditions? _conditions;

  SurveyQuestionType get type => SurveyQuestionType.fromString(typeString);
  int get position => getValue(SurveyQuestionKey.position) ?? 0;
  String get typeString => getValue(SurveyQuestionKey.type);
  String get text => getValue(SurveyQuestionKey.text);
  String? get hint => getValue(SurveyQuestionKey.hint);
  int? get rangeMin => getValue(SurveyQuestionKey.range_min);
  int? get rangeMax => getValue(SurveyQuestionKey.range_max);
  List<Condition> get conditions => _conditions?.getConditions() ?? [];
  // Optional question can be skipped
  bool get optional => getValue(SurveyQuestionKey.optional) ?? false;

  SurveyQuestion(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot()) {
    if (getValue(SurveyQuestionKey.conditions) != null) {
      _conditions = Conditions.fromArray(getValue(SurveyQuestionKey.conditions));
    }

    dynamic choicesValue = getValue(SurveyQuestionKey.choices);
    if (![SurveyQuestionType.range, SurveyQuestionType.choices].contains(type)) {
      // For other types we don't need to specify choices
      return;
    }
    switch (type) {
      case SurveyQuestionType.range:        // Range of values
        if (rangeMin == null || rangeMax == null) {
          _logger.log(Level.SEVERE, 'Range question without range_min or range_max');
          return;
        }
        if (rangeMin! >= rangeMax! || rangeMin! < 0 || rangeMax! < 1) {
          _logger.log(Level.SEVERE,
              'range_max needs to be greater than range_min and both need to be positive.');
          return;
        }
        for (int choice = rangeMin!; choice <= rangeMax!; choice++) {
          choices.add(SurveyQuestionChoice(choice.toString(), choice.toString()));
        }
        break;
      case SurveyQuestionType.choices:
        if (choicesValue is List) {
          // List of value/text items
          choices = choicesValue.map(
                  (item) => SurveyQuestionChoice(item['value'], item['text'])).toList();
        } else {
          choices = _getSpecialChoices(SurveyQuestionSpecialChoices.fromString(choicesValue));
        }
        if (choices.isEmpty) {
          _logger.log(Level.SEVERE, 'No choices found for question: $text');
        }
        break;
      default:
        // Other types don't need choices.
        break;
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
          SurveyQuestionChoice("0", "Not at all"),
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
      case SurveyQuestionSpecialChoices.panas_sf:
        return [
          SurveyQuestionChoice("1", "Very slightly or not at all"),
          SurveyQuestionChoice("2", "A little"),
          SurveyQuestionChoice("3", "Moderately"),
          SurveyQuestionChoice("4", "Quite a bit"),
          SurveyQuestionChoice("5", "Extremely"),
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
  final CustomLogPrinter _logger = CustomLogPrinter('Survey');

  List<SurveyQuestion>? _questions;

  String get abbreviation => getValue(SurveyKey.abbreviation) ?? "";
  String get name => getValue(SurveyKey.name) ?? "";
  String get introText => getValue(SurveyKey.intro_text) ?? "";
  Duration get duration => Duration(minutes: getValue(SurveyKey.duration_minutes) ?? 0);

  Survey(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());

  Future<bool> loadQuestions({bool fromCache = false}) async {
    _logger.log(Level.INFO, 'Loading questions for survey ${this.id} fromCache = $fromCache');
    List<FirebaseEntity>? entities = await _firestoreManager.queryEntities(
        [Table.surveys, Table.questions], [this.id],
        fromCacheWithKey: fromCache ? "survey_${this.id}_questions" : null,
        orderBy: SurveyQuestionKey.position.name
    );

    if (entities == null) {
      return false;
    }
    _questions = entities.map((firebaseEntity) => SurveyQuestion(firebaseEntity)).toList();
    _logger.log(Level.INFO, "Loaded ${_questions!.length} questions.");
    return true;
  }

  List<SurveyQuestion>? getQuestions() {
    return _questions;
  }
}
