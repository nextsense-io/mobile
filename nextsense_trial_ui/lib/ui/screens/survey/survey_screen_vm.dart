import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/survey/condition.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey_result.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class SurveyScreenViewModel extends ViewModel {

  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SurveyScreenViewModel');
  final RunnableSurvey runnableSurvey;
  SurveyResult? _surveyResult;

  Map<String, dynamic>? formValues;
  int currentPageNumber = 0;

  Survey get survey => runnableSurvey.survey;

  SurveyScreenViewModel(this.runnableSurvey);

  @override
  void init() {
    startOrResumeSurvey();
  }

  void startOrResumeSurvey() async {
    setBusy(true);
    bool startSurvey = false;
    if (runnableSurvey is ScheduledSurvey) {
      ScheduledSurvey scheduledSurvey = runnableSurvey as ScheduledSurvey;
      if (scheduledSurvey.state == SurveyState.not_started) {
        startSurvey = true;
      } else if (scheduledSurvey.state == SurveyState.partially_completed &&
          scheduledSurvey.resultId != null) {
        _logger.log(Level.INFO, "Resuming survey: ${runnableSurvey.survey.name}");
        SurveyResult? result = await _surveyManager.getSurveyResult(scheduledSurvey.resultId!);
        if (result != null) {
          _surveyResult = result;
          formValues = Map.from(_surveyResult!.getData()!);
        } else {
          _logger.log(Level.WARNING,
              "Survey result not found: ${scheduledSurvey.resultId}, restarting survey.");
          startSurvey = true;
        }
      }
    } else {
      // For Adhoc, no always start a new survey, if stopped before the end, it's marked as
      // cancelled.
      startSurvey = true;
    }
    if (startSurvey) {
      _logger.log(Level.INFO, "Starting survey: ${runnableSurvey.survey.name}");
      _surveyResult = await _surveyManager.startSurvey(runnableSurvey);
    }
    setBusy(false);
    setInitialised(true);
  }

  Future<bool> submit({required Map<String, dynamic> formData, required bool completed}) async {
    _logger.log(Level.INFO, "Submitting survey form.");
    setBusy(true);
    // Seems like the form validation is not working correctly, at least make sure every mandatory
    // entry got a value.
    bool valid = true;
    if (formData.length != getVisibleQuestions().length) {
      valid = false;
    }
    for (SurveyQuestion question in getVisibleQuestions()) {
      if (!question.optional && formData[question.id] == null) {
        valid = false;
      }
    }
    bool updated = await _surveyManager.stopSurvey(runnableSurvey: runnableSurvey,
        state: completed && valid ? SurveyState.completed : SurveyState.partially_completed,
        data: formData, surveyResultId: _surveyResult!.id);
    setBusy(false);
    return updated;
  }

  List<SurveyQuestion> getVisibleQuestions() {
    List<SurveyQuestion> visibleQuestions = [];
    _logger.log(Level.INFO, "Showing survey: ${survey.id}");
    for (SurveyQuestion question in survey.getQuestions() ?? []) {
      bool questionVisible = true;
      if (question.conditions.isNotEmpty) {
        if (formValues == null) {
          questionVisible = false;
        } else {
          for (Condition condition in question.conditions) {
            dynamic questionValue = formValues![condition.questionId];
            _logger.log(Level.FINE,
                "${question.id} showing if ${condition.toString()}: value: $questionValue");
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