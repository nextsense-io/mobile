import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum ScheduledSurveyKey {
  survey_id,  // Reference to doc from 'surveys' collection
  planned_survey,  // Reference to doc from 'study->planned_surveys' collection
  status,
  day_number,
  days_to_complete,
  period,
  result_id,  // Survey result id.
  schedule_type,  // See ScheduleType in planned_activity.dart
  triggered_by_session_id,
  triggered_by_survey_id
}

class ScheduledSurvey extends FirebaseEntity<ScheduledSurveyKey> implements Task, RunnableSurvey {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSurvey');
  // Day survey will appear.
  final StudyDay? day;

  late Survey survey;
  // Time before this survey should be completed, or it will be marked as skipped.
  late DateTime shouldBeCompletedBefore;

  ScheduleType get scheduleType => ScheduleType.scheduled;
  SurveyState get state => SurveyState.fromString(getValue(ScheduledSurveyKey.status) ??
      SurveyState.not_started.name);
  Period get period => Period.fromString(getValue(ScheduledSurveyKey.period));
  String get plannedSurveyId => getValue(ScheduledSurveyKey.planned_survey).id;
  String? get scheduledSurveyId => id;
  String? get resultId => getValue(ScheduledSurveyKey.result_id);
  bool get isCompleted => state == SurveyState.completed;
  bool get isSkipped => state == SurveyState.skipped;
  bool get notStarted => state == SurveyState.not_started;

  factory ScheduledSurvey.fromSurveyTrigger(FirebaseEntity firebaseEntity,
      {required Survey survey, required PlannedSurvey plannedSurvey, required String triggeredBy}) {
    firebaseEntity.setValue(ScheduledSurveyKey.triggered_by_survey_id, triggeredBy);
    return ScheduledSurvey._fromTrigger(firebaseEntity, survey: survey,
        plannedSurvey: plannedSurvey);
  }

  factory ScheduledSurvey.fromSessionTrigger(FirebaseEntity firebaseEntity,
      {required Survey survey, required PlannedSurvey plannedSurvey, required String triggeredBy}) {
    firebaseEntity.setValue(ScheduledSurveyKey.triggered_by_session_id, triggeredBy);
    return ScheduledSurvey(firebaseEntity, survey: survey, plannedSurvey: plannedSurvey);
  }

  factory ScheduledSurvey._fromTrigger(FirebaseEntity firebaseEntity, {required Survey survey,
      required PlannedSurvey plannedSurvey}) {
    firebaseEntity.setValue(ScheduledSurveyKey.planned_survey, plannedSurvey);
    firebaseEntity.setValue(ScheduledSurveyKey.status, SurveyState.not_started.name);
    firebaseEntity.setValue(ScheduledSurveyKey.days_to_complete, 1);
    return ScheduledSurvey(firebaseEntity, survey: survey, plannedSurvey: plannedSurvey);
  }

  ScheduledSurvey(FirebaseEntity firebaseEntity, {required this.survey, this.day,
    PlannedSurvey? plannedSurvey}) : super(firebaseEntity.getDocumentSnapshot()) {

    int? _daysToComplete = getValue(ScheduledSurveyKey.days_to_complete);
    // Initialize from planned survey.
    if (plannedSurvey != null) {
      plannedSurvey = plannedSurvey;
      setPlannedSurvey(plannedSurvey.reference);
      _daysToComplete = plannedSurvey.daysToComplete;
      setValue(ScheduledSurveyKey.survey_id, survey.id);
    }

    // Day date is at 00:00, so we need to set completion time next midnight.
    if (day != null) {
      shouldBeCompletedBefore = day!.date.add(Duration(days: _daysToComplete!));
      setValue(ScheduledSurveyKey.day_number, day!.dayNumber);
    }
  }

  // Set state of protocol in Firestore.
  void setState(SurveyState state) {
    setValue(ScheduledSurveyKey.status, state.name);
  }

  void setPeriod(Period period) {
    setValue(ScheduledSurveyKey.period, period.name);
  }

  void setPlannedSurvey(DocumentReference plannedSurveyRef) {
    setValue(ScheduledSurveyKey.planned_survey, plannedSurveyRef);
  }

  // Survey didn't start in time, should be skipped.
  bool isLate() {
    if (state != SurveyState.not_started) {
      return false;
    }
    final currentTime = DateTime.now();
    return currentTime.isAfter(shouldBeCompletedBefore.subtract(Duration(seconds: 1)));
  }

  // Update fields and save to Firestore by default.
  @override
  Future<bool> update({required SurveyState state, required String resultId}) async {
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
    setValue(ScheduledSurveyKey.result_id, resultId);

    return await save();
  }

  // Task implementation.
  @override
  bool get completed => isCompleted;

  @override
  bool get skipped => isSkipped;

  @override
  Duration? get duration => survey.duration;

  @override
  String get title => survey.name + ' survey';

  @override
  String get intro => survey.introText;

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay? get windowEndTime => TimeOfDay(hour: 23, minute: 59);

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay get windowStartTime => TimeOfDay(hour: 0, minute: 0);

  @override
  DateTime? get startDate => day!.date;

  @override
  TaskType get type => TaskType.survey;
}