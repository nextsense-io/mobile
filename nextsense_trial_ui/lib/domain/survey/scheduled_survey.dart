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
  survey,  // Reference to doc from 'surveys' collection
  planned_survey,  // Reference to doc from 'study->planned_surveys' collection
  status,
  day_number,
  days_to_complete,
  period,
  data
}

class ScheduledSurvey extends FirebaseEntity<ScheduledSurveyKey> implements Task, RunnableSurvey {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSurvey');
  // Day survey will appear.
  final StudyDay day;

  late Survey survey;
  // Time before this survey should be completed, or it will be marked as skipped.
  late DateTime shouldBeCompletedBefore;

  RunnableSurveyType get type => RunnableSurveyType.scheduled;
  SurveyState get state => surveyStateFromString(getValue(ScheduledSurveyKey.status));
  Period get period => Period.fromString(getValue(ScheduledSurveyKey.period));
  String get plannedSurveyId => getValue(ScheduledSurveyKey.planned_survey).id;
  bool get isCompleted => state == SurveyState.completed;
  bool get isSkipped => state == SurveyState.skipped;
  bool get notStarted => state == SurveyState.not_started;

  ScheduledSurvey(FirebaseEntity firebaseEntity, this.survey, this.day,
      {PlannedSurvey? plannedSurvey}) : super(firebaseEntity.getDocumentSnapshot()) {

    int? _daysToComplete = getValue(ScheduledSurveyKey.days_to_complete);
    // Initialize from planned survey.
    if (plannedSurvey != null) {
      setPlannedSurvey(plannedSurvey.reference);
      _daysToComplete = plannedSurvey.daysToComplete;
      setValue(ScheduledSurveyKey.days_to_complete, _daysToComplete);
      setValue(ScheduledSurveyKey.survey, survey.id);
    }

    // Day date is at 00:00, so we need to set completion time next midnight.
    shouldBeCompletedBefore = day.date.add(Duration(days: _daysToComplete!));

    setValue(ScheduledSurveyKey.day_number, day.dayNumber);
  }

  // Set state of protocol in Firestore.
  void setState(SurveyState state) {
    setValue(ScheduledSurveyKey.status, state.name);
  }

  void setPeriod(Period period) {
    setValue(ScheduledSurveyKey.period, period.name);
  }

  Map<String, dynamic> getData() {
    return getValue(ScheduledSurveyKey.data) ?? Map();
  }

  // Save submitted survey data.
  void setData(Map<String, dynamic> data) {
    setValue(ScheduledSurveyKey.data, data);
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
  Future<bool> update({required SurveyState state, Map<String, dynamic>? data,
      bool persist = true}) async {
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
      return await save();
    }
    return true;
  }

  // Task implementation.
  @override
  bool get completed => isCompleted;

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
}