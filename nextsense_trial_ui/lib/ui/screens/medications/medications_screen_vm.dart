import 'dart:async';

import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/medication/scheduled_medication.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/managers/medication_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class MedicationsScreenViewModel extends ViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();
  final MedicationManager _medicationManager = getIt<MedicationManager>();
  final studyDayChangeStream = StreamController<int>.broadcast();

  // Current selected day in calendar
  StudyDay? selectedDay;

  List<StudyDay> get _days => _studyManager.days;
  // Returns current day of study
  StudyDay? get _today => _studyManager.today;
  int get selectedDayNumber => selectedDay?.dayNumber ?? 0;
  List<ScheduledMedication> get scheduledMedications => _medicationManager.scheduledMedications;
  List<PlannedMedication> get plannedMedications => _medicationManager.plannedMedications;

  @override
  void dispose() {
    super.dispose();
    studyDayChangeStream.close();
  }

  List<StudyDay> getDays() {
    return _days;
  }

  void selectDay(StudyDay day) {
    selectedDay = day;
    notifyListeners();
    studyDayChangeStream.sink.add(day.dayNumber);
  }

  void selectToday() {
    if (_today != null) {
      selectDay(_today!);
    }
  }

  bool dayHasAnyScheduledMedications(StudyDay day) {
    return getScheduledMedicationsByDay(day).isNotEmpty;
  }

  List<ScheduledMedication> getScheduledMedicationsByDay(StudyDay day) {
    List<ScheduledMedication> result = [];
    for (var scheduledMedication in scheduledMedications) {
      if (scheduledMedication.getStudyDay(_studyManager.currentStudyStartDate!) == day) {
        result.add(scheduledMedication);
      }
    }
    result.sort((p1, p2) => p1.startDateTime!.compareTo(p2.startDateTime!));
    return result;
  }
}