import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/medication/medication.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

/// Each entry corresponds to a field name in the database instance.
enum ScheduledMedicationKey {
  planned_medication_id,  // Planned medication id
  schedule_type,  // See ScheduleType in planned_activity.dart
  status,  // State, see MedicationState in protocol.dart
  start_date,  // Used to query by date, string format
  start_datetime,  // Used to get the exact datetime, string format
  taken_datetime,  // Time when the medication was taken, DateTime format
  triggered_by_medication,  // Planned activity id that triggered the medication
  triggered_by_survey,
  period  // Period of the medication, string format
}

class ScheduledMedication extends FirebaseEntity<ScheduledMedicationKey> implements Task {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledMedication');

  @override
  late DateTime? startDate;  // Date without time for calculations.
  late DateTime? startDateTime;
  // Time constraints for the protocol.
  late DateTime? allowedStartBefore;
  late DateTime? allowedStartAfter;

  late PlannedMedication _plannedMedication;

  String get plannedMedicationId => getValue(ScheduledMedicationKey.planned_medication_id);
  String get id => id;
  String get name => _plannedMedication.name;
  String get indication => _plannedMedication.indication;
  Period? get period => Period.fromString(getValue(ScheduledMedicationKey.period));
  set takenDateTime(DateTime takenDateTime) => setValue(ScheduledMedicationKey.taken_datetime,
      takenDateTime);

  MedicationState get state => MedicationState.fromString(getValue(ScheduledMedicationKey.status));
  bool get isTaken => state == MedicationState.taken_on_time ||
      state == MedicationState.taken_early ||
      state == MedicationState.taken_late;
  ScheduleType get scheduleType => ScheduleType.scheduled;

  factory ScheduledMedication.fromStudyDay(
      {required FirebaseEntity firebaseEntity, required PlannedMedication plannedMedication,
      required StudyDay studyDay, required DateTime startTime}) {
    // Needed for later push notifications processing at backend.
    firebaseEntity.setValue(ScheduledMedicationKey.start_date, studyDay.dateAsString);
    DateTime startDateTime = studyDay.date.add(
        Duration(hours: startTime.hour, minutes: startTime.minute));
    firebaseEntity.setValue(ScheduledMedicationKey.start_datetime, startDateTime);
    return ScheduledMedication(firebaseEntity, plannedMedication);
  }

  ScheduledMedication(FirebaseEntity firebaseEntity, PlannedMedication plannedMedication) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager()) {
    super.setValues(firebaseEntity.getValues());
    _plannedMedication = plannedMedication;
    setValue(ScheduledMedicationKey.planned_medication_id, plannedMedication.id);
    setValue(ScheduledMedicationKey.schedule_type, plannedMedication.scheduleType.name);
    startDate = DateTime.parse(firebaseEntity.getValue(ScheduledMedicationKey.start_date));
    startDateTime = getStartDateTime();
    allowedStartAfter = startDateTime!.subtract(
        Duration(minutes: plannedMedication.allowedEarlyStartTimeMinutes ?? 0));
    allowedStartBefore = startDateTime!.add(
        Duration(minutes: plannedMedication.allowedLateStartTimeMinutes ?? 0));
  }

  // Set state of protocol in firebase
  void setState(MedicationState state) {
    setValue(ScheduledMedicationKey.status, state.name);
  }

  StudyDay getStudyDay(DateTime studyStartDateTime) {
    Duration difference = startDate!.difference(studyStartDateTime.dateNoTime);
    int dayNumber = difference.inDays + 1;
    return StudyDay(studyStartDateTime.add(Duration(days: difference.inDays)), dayNumber);
  }

  DateTime? getStartDateTime() {
    dynamic value = getValue(ScheduledMedicationKey.start_datetime);
    if (value is Timestamp) {
      return value != null ? value.toDate() : null;
    }
    return getValue(ScheduledMedicationKey.start_datetime);
  }

  void setPeriod(Period period) {
    setValue(ScheduledMedicationKey.period, period.name);
  }

  setTakenDateTime(DateTime takenDateTime) {
    setValue(ScheduledMedicationKey.taken_datetime, takenDateTime.toIso8601String());
  }

  // Medication is within desired window to start.
  bool isAllowedToBeTaken() {
    final currentTime = DateTime.now();
    // Subtracts 1 second to make sure isAfter method works correctly on beginning of each minute
    // i.e 11:00:00 is after 10:59:59.
    return currentTime.isAfter(allowedStartAfter!.subtract(Duration(seconds: 1)))
        && currentTime.isBefore(allowedStartBefore!);
  }

  // Medication didn't start in time, should be skipped.
  bool isLate() {
    if ([MedicationState.skipped].contains(state)) {
      return false;
    }
    final currentTime = DateTime.now();
    return state == MedicationState.before_time
        && currentTime.isAfter(allowedStartBefore!.subtract(Duration(seconds: 1)));
  }

  // Update fields and save to Firestore by default.
  Future<bool> update({required MedicationState state, DateTime? takenDateTime,
      bool persist = true}) async {
    if (isTaken) {
      _logger.log(Level.INFO, 'Medication $name already taken. Cannot change its state.');
      return false;
    } else if (this.state == MedicationState.skipped) {
      _logger.log(Level.INFO, 'Medication $name already skipped. Cannot change its state.');
      return false;
    }
    _logger.log(Level.INFO, 'Medication state changing from ${this.state} to $state');
    setState(state);
    if (takenDateTime != null) {
      setTakenDateTime(takenDateTime);
    }
    if (persist) {
      return await save();
    }
    return true;
  }

  // Task implementation.
  @override
  bool get completed => isTaken;

  @override
  bool get skipped => state == MedicationState.skipped;

  @override
  Duration? get duration => Duration(seconds: 0);

  @override
  String get title => name;

  @override
  String get intro => indication;

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay? get windowEndTime => TimeOfDay.fromDateTime(allowedStartBefore!);

  @override
  // Surveys can be completed anywhere in the day.
  TimeOfDay get windowStartTime => TimeOfDay.fromDateTime(allowedStartAfter!);

  @override
  TaskType get type => TaskType.medication;
}