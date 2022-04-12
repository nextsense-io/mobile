import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';

class AdhocSurvey implements RunnableSurvey {

  late Survey survey;

  RunnableSurveyType get type => RunnableSurveyType.adhoc;

  AdhocSurvey(this.survey);

  @override
  bool update({required SurveyState state,
    Map<String, dynamic>? data, bool persist = true}) {
    // State of survey is not tracked for now
    //TODO(alex): store adhoc survey data
    return true;
  }

}