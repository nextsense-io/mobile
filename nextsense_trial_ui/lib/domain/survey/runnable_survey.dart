import 'package:nextsense_trial_ui/domain/survey/survey.dart';

enum RunnableSurveyType {
  scheduled,
  adhoc
}

// Class to represents survey and track its state and data
abstract class RunnableSurvey {
  late Survey survey;

  RunnableSurveyType get type;

  bool update({required SurveyState state,
    Map<String, dynamic>? data, bool persist = true});
}