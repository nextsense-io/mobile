import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/planned_session.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

/// Each entry corresponds to a field name in the database instance.
enum ScheduledSessionKey {
  planned_session_id,  // Planned session id
  schedule_type,  // See ScheduleType in planned_activity.dart
  session_ids,  // List of session objets
  status,  // State, see ProtocolState in protocol.dart
  start_date,  // Used to query by date, string format
  start_datetime,  // Used to get the exact datetime, string format
  triggered_by_session_id,  // Planned activity id that triggered the session
  triggered_by_survey_id
}

class ScheduledSession extends FirebaseEntity<ScheduledSessionKey> implements Task,
    RunnableProtocol {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSession');

  late Protocol protocol;
  @override
  late DateTime? startDate;

  // Start time - hours & minutes only.
  late DateTime? startTime;
  // Time constraints for the protocol.
  late DateTime? allowedStartBefore;
  late DateTime? allowedStartAfter;

  String get plannedSessionId => getValue(ScheduledSessionKey.planned_session_id);
  String get scheduledSessionId => id;
  ProtocolState get state => protocolStateFromString(getValue(ScheduledSessionKey.status));
  bool get isCompleted => state == ProtocolState.completed;
  bool get isSkipped => state == ProtocolState.skipped;
  bool get isCancelled => state == ProtocolState.cancelled;
  ScheduleType get scheduleType => ScheduleType.scheduled;
  String? get lastSessionId {
    var sessions = getValue(ScheduledSessionKey.session_ids);
    if (sessions is List) {
      return sessions.last;
    }
    return sessions;
  }

  factory ScheduledSession.fromStudyDay(
      FirebaseEntity firebaseEntity, PlannedSession plannedSession, StudyDay studyDay) {
    // Needed for later push notifications processing at backend.
    firebaseEntity.setValue(ScheduledSessionKey.start_date, studyDay.dateAsString);
    DateTime startDateTime = studyDay.date.add(
        Duration(hours: plannedSession.startTime!.hour,
            minutes: plannedSession.startTime!.minute));
    firebaseEntity.setValue(ScheduledSessionKey.start_datetime, startDateTime.toString());
    return ScheduledSession(firebaseEntity, plannedSession);
  }

  factory ScheduledSession.fromSessionTrigger(FirebaseEntity firebaseEntity,
      {required PlannedSession plannedSession, required String triggeredBy}) {
    firebaseEntity.setValue(ScheduledSessionKey.triggered_by_session_id, triggeredBy);
    return ScheduledSession._fromTrigger(firebaseEntity, plannedSession);
  }

  factory ScheduledSession.fromSurveyTrigger(FirebaseEntity firebaseEntity,
      {required PlannedSession plannedSession, required String triggeredBy}) {
    firebaseEntity.setValue(ScheduledSessionKey.triggered_by_survey_id, triggeredBy);
    return ScheduledSession(firebaseEntity, plannedSession);
  }

  factory ScheduledSession._fromTrigger(FirebaseEntity firebaseEntity,
      PlannedSession plannedSession) {
    firebaseEntity.setValue(ScheduledSessionKey.schedule_type, plannedSession.scheduleType.name);
    firebaseEntity.setValue(ScheduledSessionKey.planned_session_id, plannedSession.id);
    firebaseEntity.setValue(ScheduledSessionKey.session_ids, []);
    firebaseEntity.setValue(ScheduledSessionKey.status, ProtocolState.not_started.name);
    DateTime now = DateTime.now();
    firebaseEntity.setValue(ScheduledSessionKey.start_date, now.date);
    firebaseEntity.setValue(ScheduledSessionKey.start_datetime, now.toString());
    return ScheduledSession(firebaseEntity, plannedSession);
  }

  ScheduledSession(FirebaseEntity firebaseEntity, PlannedSession plannedAssessment) :
        super(firebaseEntity.getDocumentSnapshot()) {
    protocol = plannedAssessment.protocol!;
    startTime = plannedAssessment.startTime;
    allowedStartAfter = DateTime.parse(firebaseEntity.getValue(ScheduledSessionKey.start_datetime))
        .subtract(Duration(minutes: plannedAssessment.allowedEarlyStartTimeMinutes ?? 0));
    allowedStartBefore = DateTime.parse(
        firebaseEntity.getValue(ScheduledSessionKey.start_datetime))
        .add(Duration(minutes: plannedAssessment.allowedLateStartTimeMinutes ?? 0));
    startDate = DateTime.parse(getValue(ScheduledSessionKey.start_date));
  }

  // Set state of protocol in firebase
  void setState(ProtocolState state) {
    setValue(ScheduledSessionKey.status, state.name);
  }

  int getStudyDay(DateTime studyStartDateTime) {
    Duration difference = startDate!.difference(studyStartDateTime.dateNoTime);
    return difference.inDays + 1;
  }

  // Store session in array of sessions
  void addSession(String sessionId) {
    var currentSessionList = getValue(ScheduledSessionKey.session_ids);
    if (currentSessionList is List) {
      if (!currentSessionList.contains(sessionId)) {
        currentSessionList.add(sessionId);
      }
    } else {
      currentSessionList = <String>[sessionId];
    }
    setValue(ScheduledSessionKey.session_ids, currentSessionList);
  }

  // Protocol is within desired window to start.
  bool isAllowedToStart() {
    final currentTime = DateTime.now();
    // Subtracts 1 second to make sure isAfter method works correctly on beginning of each minute
    // i.e 11:00:00 is after 10:59:59.
    return currentTime.isAfter(allowedStartAfter!.subtract(Duration(seconds: 1)))
        && currentTime.isBefore(allowedStartBefore!);
  }

  // Protocol didn't start in time, should be skipped.
  bool isLate() {
    if ([ProtocolState.completed, ProtocolState.skipped].contains(state)) {
      return false;
    }
    final currentTime = DateTime.now();
    return state == ProtocolState.not_started
        && currentTime.isAfter(allowedStartBefore!.subtract(Duration(seconds: 1)));
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
  bool get skipped => isSkipped;

  @override
  Duration? get duration => protocol.minDuration;

  @override
  String get title => protocol.nameForUser + ' recording';

  @override
  String get intro => protocol.intro;

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay? get windowEndTime => TimeOfDay.fromDateTime(allowedStartBefore!);

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay get windowStartTime => TimeOfDay.fromDateTime(allowedStartAfter!);

  @override
  TaskType get type => TaskType.recording;
}