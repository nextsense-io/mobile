import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';

// Class to represents survey and track its state and data.
abstract class RunnableSurvey {
  late Survey survey;

  ScheduleType get scheduleType;
  String get plannedSurveyId;
  String? get scheduledSurveyId;
  String? get resultId;

  Future<bool> update({required SurveyState state, required String resultId});
}