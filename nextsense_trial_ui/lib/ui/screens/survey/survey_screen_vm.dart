import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/survey/condition.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SurveyScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreenViewModel');
  final RunnableSurvey runnableSurvey;

  Map<String, dynamic>? formValues = null;
  int currentPageNumber = 0;

  Survey get survey => runnableSurvey.survey;

  SurveyScreenViewModel(this.runnableSurvey);

  @override
  void init() {
    loadQuestionsIfNeeded();
  }

  void loadQuestionsIfNeeded() {
    if (runnableSurvey is ScheduledSurvey) {
      ScheduledSurvey scheduledSurvey = runnableSurvey as ScheduledSurvey;
      if (scheduledSurvey.state == SurveyState.partially_completed) {
        formValues = Map.from(scheduledSurvey.getData());
      }
    }
  }

  Future<bool> submit(Map<String, dynamic> formData, bool completed) async {
    _logger.log(Level.INFO, "Submitting survey form.");
    setBusy(true);
    bool updated = await runnableSurvey.update(
        state: completed ? SurveyState.completed : SurveyState.partially_completed,
        data: formData
    );
    setBusy(false);
    return updated;
  }

  List<SurveyQuestion> getVisibleQuestions() {
    List<SurveyQuestion> visibleQuestions = [];
    for (SurveyQuestion question in survey.getQuestions()) {
      bool questionVisible = true;
      if (question.conditions.isNotEmpty) {
        if (formValues == null) {
          questionVisible = false;
        } else {
          for (Condition condition in question.conditions) {
            dynamic questionValue = formValues![condition.key];
            // _logger.log(Level.FINE,
            //     "${question.id} showing if ${condition.toString()}: value: ${questionValue}");
            if (!condition.isTrue(questionValue)) {
              questionVisible = false;
              break;
            }
          }
        }
      }
      if (questionVisible) {
        visibleQuestions.add(question);
      }
    }
    if (formValues != null) {
      for (SurveyQuestion question in visibleQuestions) {
        if (!formValues!.containsKey(question.id)) {
          formValues![question.id] = null;
        }
      }
    }
    return visibleQuestions;
  }
}