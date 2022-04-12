
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:stacked/stacked.dart';

enum SurveyScreenStep {
  intro,
  form
}

class SurveyScreenViewModel extends BaseViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreenViewModel');

  final RunnableSurvey runnableSurvey;

  Survey get survey => runnableSurvey.survey;

  SurveyScreenViewModel(this.runnableSurvey);

  // Intro or form
  int _currentStep = SurveyScreenStep.intro.index;
  int get currentStep => _currentStep;

  set currentStep(int currentStep) {
    _currentStep = currentStep;
    notifyListeners();
  }

  void init() async {
  }

  void submit(Map<String, dynamic> formData) {
    _logger.log(Level.INFO, "submit survey form - $formData");

    runnableSurvey.update(
        state: SurveyState.completed,
        data: formData
    );
  }

}