
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:stacked/stacked.dart';

enum SurveyScreenStep {
  intro,
  form
}

class SurveyScreenViewModel extends BaseViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreenViewModel');

  final ScheduledSurvey scheduledSurvey;

  Survey get survey => scheduledSurvey.survey;

  SurveyScreenViewModel(this.scheduledSurvey);

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

    scheduledSurvey.update(
        state: SurveyState.completed,
        data: formData
    );
  }

}