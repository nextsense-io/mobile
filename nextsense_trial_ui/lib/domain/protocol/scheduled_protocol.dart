import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

/// Each entry corresponds to a field name in the database instance.
enum ScheduledProtocolKey {
  protocol,  // Protocol key
  sessions,  // List of session objets
  status,  // State, see ProtocolState in protocol.dart
  start_date,  // Used to query by date, string format
  start_datetime  // Used to get the exact datetime, string format
}

class ScheduledProtocol extends FirebaseEntity<ScheduledProtocolKey> implements Task,
    RunnableProtocol {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledProtocol');

  late Protocol protocol;
  late List<Survey> postRecordingSurveys;
  late DateTime startDate;

  // Start time - hours & minutes only.
  late DateTime startTime;
  // Time constraints for the protocol.
  late DateTime allowedStartBefore;
  late DateTime allowedStartAfter;

  ProtocolState get state => protocolStateFromString(getValue(ScheduledProtocolKey.status));
  bool get isCompleted => state == ProtocolState.completed;
  bool get isSkipped => state == ProtocolState.skipped;
  bool get isCancelled => state == ProtocolState.cancelled;
  RunnableProtocolType get type => RunnableProtocolType.scheduled;
  String? get lastSessionId {
    var sessions = getValue(ScheduledProtocolKey.sessions);
    if (sessions is List) {
      return sessions.last;
    }
    return sessions;
  }

  factory ScheduledProtocol.fromStudyDay(
      FirebaseEntity firebaseEntity, PlannedAssessment plannedAssessment, StudyDay studyDay) {
    // Needed for later push notifications processing at backend.
    firebaseEntity.setValue(ScheduledProtocolKey.start_date, studyDay.dateAsString);
    DateTime startDateTime = studyDay.date.add(
        Duration(hours: plannedAssessment.startTime.hour,
            minutes: plannedAssessment.startTime.minute));
    firebaseEntity.setValue(ScheduledProtocolKey.start_datetime, startDateTime.toString());
    return ScheduledProtocol(firebaseEntity, plannedAssessment);
  }

  ScheduledProtocol(FirebaseEntity firebaseEntity, PlannedAssessment plannedAssessment) :
        super(firebaseEntity.getDocumentSnapshot()) {
    protocol = plannedAssessment.protocol!;
    startTime = plannedAssessment.startTime;
    allowedStartAfter = DateTime.parse(firebaseEntity.getValue(ScheduledProtocolKey.start_datetime))
        .subtract(Duration(minutes: plannedAssessment.allowedEarlyStartTimeMinutes));
    allowedStartBefore = DateTime.parse(
        firebaseEntity.getValue(ScheduledProtocolKey.start_datetime))
        .add(Duration(minutes: plannedAssessment.allowedLateStartTimeMinutes));
    postRecordingSurveys = plannedAssessment.postSurveys;
    startDate = DateTime.parse(getValue(ScheduledProtocolKey.start_date));
  }

  // Set state of protocol in firebase
  void setState(ProtocolState state) {
    setValue(ScheduledProtocolKey.status, state.name);
  }

  int getStudyDay(DateTime studyStartDateTime) {
    Duration difference = startDate.difference(studyStartDateTime.dateNoTime);
    return difference.inDays + 1;
  }

  // Store session in array of sessions
  void addSession(String sessionId) {
    var currentSessionList = getValue(ScheduledProtocolKey.sessions);
    if (currentSessionList is List) {
      if (!currentSessionList.contains(sessionId)) {
        currentSessionList.add(sessionId);
      }
    } else {
      currentSessionList = <String>[sessionId];
    }
    setValue(ScheduledProtocolKey.sessions, currentSessionList);
  }

  // Protocol is within desired window to start.
  bool isAllowedToStart() {
    final currentTime = DateTime.now();
    // Subtracts 1 second to make sure isAfter method works correctly on beginning of each minute
    // i.e 11:00:00 is after 10:59:59.
    return currentTime.isAfter(allowedStartAfter.subtract(Duration(seconds: 1)))
        && currentTime.isBefore(allowedStartBefore);
  }

  // Protocol didn't start in time, should be skipped.
  bool isLate() {
    if ([ProtocolState.completed, ProtocolState.skipped].contains(state)) {
      return false;
    }
    final currentTime = DateTime.now();
    return state == ProtocolState.not_started
        && currentTime.isAfter(allowedStartBefore.subtract(Duration(seconds: 1)));
  }

  // Update fields and save to Firestore by default.
  @override
  Future<bool> update({required ProtocolState state, String? sessionId, bool persist = true})
      async {
    if (this.state == ProtocolState.completed) {
      _logger.log(Level.INFO, 'Protocol ${protocol.name} already completed.'
          'Cannot change its state.');
      return false;
    } else if (this.state == ProtocolState.skipped) {
      _logger.log(Level.INFO, 'Protocol ${protocol.name} already skipped.'
          'Cannot change its state.');
      return false;
    }
    _logger.log(Level.WARNING,
        'Protocol state changing from ${this.state} to $state');
    setState(state);
    if (sessionId != null) {
      addSession(sessionId);
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
  Duration? get duration => protocol.minDuration;

  @override
  String get title => protocol.nameForUser + ' recording';

  @override
  String get intro => protocol.intro;

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay? get windowEndTime => TimeOfDay.fromDateTime(allowedStartBefore);

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay get windowStartTime => TimeOfDay.fromDateTime(allowedStartAfter);

  List<Survey>? get postSurveys => postRecordingSurveys;
}