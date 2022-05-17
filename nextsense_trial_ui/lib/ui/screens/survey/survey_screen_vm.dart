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

  Future<bool> submit(Map<String, dynamic> formData) async {
    _logger.log(Level.INFO, "Submitting survey form.");
    setBusy(true);
    bool updated = await runnableSurvey.update(
        state: SurveyState.completed,
        data: formData
    );
    setBusy(false);
    return updated;
  }
}