import 'package:nextsense_trial_ui/domain/survey/survey.dart';

enum RunnableSurveyType {
  scheduled,
  adhoc,
  protocol
}

// Class to represents survey and track its state and data
abstract class RunnableSurvey {
  late Survey survey;

  RunnableSurveyType get type;

  Future<bool> update(
      {required SurveyState state, Map<String, dynamic>? data, bool persist = true});
}