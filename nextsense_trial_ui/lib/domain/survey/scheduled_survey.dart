import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum ScheduledSurveyKey {
  survey, // Reference to doc from 'surveys' collection
  planned_survey, // Reference to doc from 'study->planned_surveys' collection
  status,
  day_number,
  days_to_complete,
  period,
  data
}

class ScheduledSurvey extends FirebaseEntity<ScheduledSurveyKey>
    implements RunnableSurvey {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSurvey');

  RunnableSurveyType get type => RunnableSurveyType.scheduled;

  late Survey survey;

  // Day survey will appear
  final StudyDay day;

  // Time before this survey should be completed, or it will be marked
  // as skipped
  late DateTime shouldBeCompletedBefore;

  SurveyState get state =>
      surveyStateFromString(getValue(ScheduledSurveyKey.status));

  SurveyPeriod get period =>
      surveyPeriodFromString(getValue(ScheduledSurveyKey.period));

  String get plannedSurveyId => getValue(ScheduledSurveyKey.planned_survey);

  bool get isCompleted => state == SurveyState.completed;
  bool get isSkipped => state == SurveyState.skipped;
  bool get notStarted => state == SurveyState.not_started;

  ScheduledSurvey(FirebaseEntity firebaseEntity, this.survey, this.day,
    {PlannedSurvey? plannedSurvey})
      : super(firebaseEntity.getDocumentSnapshot()) {

    int? _daysToComplete = getValue(ScheduledSurveyKey.days_to_complete);
    // Initialize from planned survey
    if (plannedSurvey != null) {
      setPlannedSurvey(plannedSurvey.id);
      _daysToComplete = plannedSurvey.daysToComplete;
      setValue(ScheduledSurveyKey.days_to_complete, _daysToComplete);
      setValue(ScheduledSurveyKey.survey, survey.id);
    }

    // Day date is at 00:00, so we need to set completion time next midnight
    shouldBeCompletedBefore =
        day.date.add(Duration(days: _daysToComplete!));

    setValue(ScheduledSurveyKey.day_number, day.dayNumber);
  }

  // Set state of protocol in firebase
  void setState(SurveyState state) {
    setValue(ScheduledSurveyKey.status, state.name);
  }

  void setPeriod(SurveyPeriod period) {
    setValue(ScheduledSurveyKey.period, period.name);
  }

  // Save submitted survey data
  void setData(Map<String, dynamic> data) {
    setValue(ScheduledSurveyKey.data, data);
  }

  void setPlannedSurvey(String plannedSurveyId) {
    setValue(ScheduledSurveyKey.planned_survey, plannedSurveyId);
  }

  // Survey didn't start in time, should be skipped
  bool isLate() {
    if (state != SurveyState.not_started)
      return false;
    final currentTime = DateTime.now();
    return currentTime
        .isAfter(shouldBeCompletedBefore.subtract(Duration(seconds: 1)));
  }

  // Update fields and save to firestore by default
  @override
  bool update({required SurveyState state,
    Map<String, dynamic>? data, bool persist = true}) {
    if (this.state == SurveyState.completed) {
      _logger.log(Level.INFO, 'Survey ${survey.name} already completed.'
          'Cannot change its state.');
      return false;
    } else if (this.state == SurveyState.skipped) {
      _logger.log(Level.INFO, 'Survey ${survey.name} already skipped.'
          'Cannot change its state.');
      return false;
    }
    _logger.log(Level.WARNING,
        'Survey state changing from ${this.state} to $state');
    setState(state);

    if (data != null) {
      setData(data);
    }
    if (persist) {
      save();
    }
    return true;
  }
}