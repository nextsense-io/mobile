import 'dart:core';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedMedicationKey {
  allowed_early_start_time_minutes,  // How many minutes the medication can be taken before the time
  allowed_late_start_time_minutes,  // How many minutes the medication can be taken after the time.
  day,  // Specific day where the session should be taken. If periodic, first day offset.
  end_day,  // Last day where the session will be scheduled when it is periodic.
  name,  // Name of the medication.
  indication,  // Use indications for the medication.
  period,  // Period of the medication defined in Period enum.
  schedule_type,  // Type of the schedule. Defined by the ScheduleType enum.
  time,  // Specific time at which the medication should be taken.
}

class PlannedMedication extends FirebaseEntity<PlannedMedicationKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedMedication');

  // Start time string in format "HH:MM".
  String? startTimeStr;
  // Contains only time part.
  List<DateTime> _startTimes = [];
  int? allowedEarlyStartTimeMinutes;
  int? allowedLateStartTimeMinutes;
  PlannedActivity? _plannedActivity;

  // defaults to specific day for legacy assessments where it was not set.
  Period get _period => Period.fromString(getValue(PlannedMedicationKey.period) ?? "");
  int? get _dayNumber => getValue(PlannedMedicationKey.day);
  int? get _lastDayNumber => getValue(PlannedMedicationKey.end_day);

  String get name => getValue(PlannedMedicationKey.name);
  String get indication => getValue(PlannedMedicationKey.indication);
  List<StudyDay>? get days => _plannedActivity?.days ?? null;
  Period get period => _period;
  List<DateTime> get startTimes => _startTimes;
  ScheduleType get scheduleType =>
      ScheduleType.fromString(getValue(PlannedMedicationKey.schedule_type));


  PlannedMedication(FirebaseEntity firebaseEntity,
      {required DateTime studyStartDate, required DateTime studyEndDate}) :
      super(firebaseEntity.getDocumentSnapshot()) {
    if (scheduleType == ScheduleType.scheduled) {
      if (_dayNumber == null || !(_dayNumber is int)) {
        throw("'day' is not set or not number in planned session");
      }
      _plannedActivity = PlannedActivity(_period, _dayNumber, _lastDayNumber, studyStartDate,
          studyEndDate);
      List<String> startTimesStr = getValue(PlannedMedicationKey.time).cast<String>();
      if (startTimesStr.isEmpty) {
        throw("'time' is not set in planned session");
      }
      for (String startTimeStr in startTimesStr) {
        int startTimeHours = int.parse(startTimeStr.split(":")[0]);
        int startTimeMinutes = int.parse(startTimeStr.split(":")[1]);
        DateTime startTime = DateTime(0, 0, 0, startTimeHours, startTimeMinutes);
        startTimes.add(startTime);
      }

      allowedEarlyStartTimeMinutes =
          getValue(PlannedMedicationKey.allowed_early_start_time_minutes) ?? 0;
      allowedLateStartTimeMinutes =
          getValue(PlannedMedicationKey.allowed_late_start_time_minutes) ?? 0;
    } else {
      _logger.log(Level.WARNING, 'Unknown or unsupported schedule type "$scheduleType"');
    }
  }
}