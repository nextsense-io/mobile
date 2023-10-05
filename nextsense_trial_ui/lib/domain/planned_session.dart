import 'package:logging/logging.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:flutter_common/utils/android_logger.dart';

enum PlannedSessionKey {
  allowed_early_start_time_minutes,  // How many minutes the protocol can be started before the time
  allowed_late_start_time_minutes,  // How many minutes the protocol can be started after the time.
  day,  // Specific day where the session should be taken. If periodic, first day offset.
  end_day,  // Last day where the session will be scheduled when it is periodic.
  parameters,  // Key/value map of session specific parameters (by type).
  period,  // Period of the session defined in Period enum.
  post_surveys,  // List of surveys that can be ran after the protocol is finished.
  schedule_type,  // Type of the schedule. Defined by the ScheduleType enum.
  time,  // Specific time at which the session should be started.
  // Id of the planned session that will be triggered by this session's completion.
  triggers_conditional_session_id,
  // Id of the planned survey that will be triggered by this session's completion.
  triggers_conditional_survey_id,
  // TODO(eric): Use the Protocol table once available.
  type,  // Defined by the ProtocolType enum. Type of the protocol like sleep, biocalibration etc.
}

enum PlannedSessionParameter {
  minDuration,
  maxDuration
}

class PlannedSession extends FirebaseEntity<PlannedSessionKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedSession');

  // Start time string in format "HH:MM".
  String? startTimeStr;
  // Contains only time part.
  DateTime? startTime;
  int? allowedEarlyStartTimeMinutes;
  int? allowedLateStartTimeMinutes;
  Protocol? protocol;
  PlannedActivity? _plannedActivity;

  // defaults to specific day for legacy assessments where it was not set.
  Period get _period => Period.fromString(getValue(PlannedSessionKey.period) ?? "");
  int? get _dayNumber => getValue(PlannedSessionKey.day);
  int? get _lastDayNumber => getValue(PlannedSessionKey.end_day);

  List<StudyDay>? get days => _plannedActivity?.days ?? null;
  ScheduleType get scheduleType =>
      ScheduleType.fromString(getValue(PlannedSessionKey.schedule_type));
  String? get triggersConditionalSessionId =>
      getValue(PlannedSessionKey.triggers_conditional_session_id);
  String? get triggersConditionalSurveyId =>
      getValue(PlannedSessionKey.triggers_conditional_survey_id);

  PlannedSession(FirebaseEntity firebaseEntity, DateTime studyStartDate, DateTime? studyEndDate) :
      super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager()) {
    if (scheduleType == ScheduleType.scheduled) {
      if (_dayNumber == null || !(_dayNumber is int)) {
        throw("'day' is not set or not number in planned session");
      }
      _plannedActivity = PlannedActivity(_period, _dayNumber, _lastDayNumber, studyStartDate,
          studyEndDate);
      startTimeStr = getValue(PlannedSessionKey.time) as String;
      // TODO(alex): check HH:MM string is correctly set
      int startTimeHours = int.parse(startTimeStr!.split(":")[0]);
      int startTimeMinutes = int.parse(startTimeStr!.split(":")[1]);
      startTime = DateTime(0, 0, 0, startTimeHours, startTimeMinutes);

      allowedEarlyStartTimeMinutes =
          getValue(PlannedSessionKey.allowed_early_start_time_minutes) ?? 0;
      allowedLateStartTimeMinutes =
          getValue(PlannedSessionKey.allowed_late_start_time_minutes) ?? 0;
    }

    // Construct protocol here based on planned session fields like
    String protocolTypeString = getValue(PlannedSessionKey.type);
    ProtocolType protocolType = protocolTypeFromString(protocolTypeString);

    if (protocolType != ProtocolType.unknown) {
      // Override default min/max durations
      Duration? minDurationOverride = getDurationOverride(
          PlannedSessionParameter.minDuration.name
      );
      Duration? maxDurationOverride = getDurationOverride(
          PlannedSessionParameter.maxDuration.name
      );

      // Create protocol assigned to current planned session
      protocol = Protocol(
          protocolType,
          startTime: startTime,
          minDuration: minDurationOverride,
          maxDuration: maxDurationOverride
      );
    } else {
      _logger.log(Level.WARNING, 'Unknown protocol "$protocolTypeString"');
    }
  }

  Duration? getDurationOverride(String field) {
    dynamic value = getParameters()[field];
    if (value == null) {
      return null;
    }
    // Value comes in HH:MM:SS format
    List<String> hms = value.split(":");
    if (hms.length != 3) {
      _logger.log(Level.WARNING, "Invalid duration override $value");
      return null;
    }
    return Duration(
        hours: int.parse(hms[0]),
        minutes: int.parse(hms[1]),
        seconds: int.parse(hms[2]));
  }

  Map<String, dynamic> getParameters() {
    return getValue(PlannedSessionKey.parameters) ?? {};
  }
}