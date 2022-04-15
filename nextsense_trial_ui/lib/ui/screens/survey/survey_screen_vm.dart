import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SurveyScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreenViewModel');

  final RunnableSurvey runnableSurvey;

  Survey get survey => runnableSurvey.survey;

  SurveyScreenViewModel(this.runnableSurvey);

  void submit(Map<String, dynamic> formData) {
    _logger.log(Level.INFO, "submit survey form - $formData");

    runnableSurvey.update(
        state: SurveyState.completed,
        data: formData
    );
  }
}