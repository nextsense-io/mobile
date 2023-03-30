import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';

enum PlannedSurveyKey {
  day,  // Specific day where the survey should be taken. If periodic, first day offset.
  end_day,  // Last day where the assessment will be scheduled when it is periodic.
  schedule_type,  // Type of the schedule. Defined by the ScheduleType enum.
  survey_id,  // Key to the survey table.
  days_to_complete,  // How many days of grace period for longer periods (weekly, monthly).
  period,  // Period of the survey defined in assessment Period enum.
  // Id of the planned session that will be triggered by this survey's completion.
  triggers_conditional_session_id,
  // Id of the planned survey that will be triggered by this survey's completion.
  triggers_conditional_survey_id,
}

class PlannedSurvey extends FirebaseEntity<PlannedSurveyKey> implements Schedulable {

  // Days on which survey will appear.
  late List<StudyDay> days = _plannedActivity.days;
  late int _daysToComplete;
  late PlannedActivity _plannedActivity;
  int? _specificDayNumber;
  int? _lastDayNumber;

  int get daysToComplete => _daysToComplete;
  ScheduleType get scheduleType => ScheduleType.fromString(
      getValue(PlannedSurveyKey.schedule_type) ?? "");
  String get surveyId => getValue(PlannedSurveyKey.survey_id);
  Period get period => Period.fromString(getValue(PlannedSurveyKey.period));
  String get triggersConditionalSessionId =>
      getValue(PlannedSurveyKey.triggers_conditional_session_id);
  String get triggersConditionalSurveyId =>
      getValue(PlannedSurveyKey.triggers_conditional_survey_id);

  PlannedSurvey(FirebaseEntity firebaseEntity, DateTime studyStartDate, DateTime studyEndDate) :
        super(firebaseEntity.getDocumentSnapshot()) {

    _specificDayNumber = getValue(PlannedSurveyKey.day);
    _lastDayNumber = getValue(PlannedSurveyKey.end_day);
    // We have following possible values for period field
    // 1. 'specific_day' - survey will take place certain day within study
    // 2. 'daily' - survey will take place each day of study
    // 3. 'weekly' - survey will take place on 8th day, 15th, etc.
    _plannedActivity = PlannedActivity(period, _specificDayNumber, _lastDayNumber, studyStartDate,
        studyEndDate);
    _initSurveyStartGracePeriod();
  }

  void _initSurveyStartGracePeriod() {
    int? _daysToComplete = getValue(PlannedSurveyKey.days_to_complete);
    if (_daysToComplete != null) {
      _daysToComplete = _daysToComplete;
    } else {
      // Default values for grace period
      _daysToComplete = 1;
      switch (period) {
        case Period.weekly:
          _daysToComplete = 7;
          break;
        default:
          break;
      }
    }
  }
}
