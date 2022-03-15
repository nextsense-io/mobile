import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_vm.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();

  DateTime? selectedDay;

  List<Assessment> assesments = [];

  // List of days that will appear for current study
  List<DateTime>? _days;

  void init() async {
    super.init();

    // TODO(alex): cache assessments (move to protocol manager?)
    assesments = await _studyManager.loadAssesments();
    final studyDays = getCurrentStudy()?.getDurationDays() ?? 0;
    _days = List<DateTime>.generate(studyDays, (i) =>
        _studyManager.currentStudyStartDate.add(Duration(days: i)));

    // TODO(alex): if current day out of range show some warning
    selectFirstDayOfStudy();
    notifyListeners();
  }

  List<Assessment> getAssessmentsByDay(DateTime day) {
    return [];
  }

  Study? getCurrentStudy() {
    return _studyManager.getCurrentStudy();
  }

  List<DateTime> getDays() {
    return _days ?? [];
  }

  void selectDay(DateTime day) {
    selectedDay = day;
    notifyListeners();
  }

  void selectFirstDayOfStudy() {
    if (_days != null)
      selectDay(_days![0]);
  }

  List<Protocol> getProtocols() {
    List<Protocol> result = [];
    for (var assessment in assesments) {
      if (assessment.protocol != null)
        result.add(assessment.protocol!);
    }
    return result;
  }

  List<Protocol> getProtocolsByDay(DateTime day) {
    List<Protocol> result = [];
    for (var assessment in assesments) {
      if (assessment.protocol != null && assessment.day.isAtSameMomentAs(day))
        result.add(assessment.protocol!);
    }
    result.sort((p1, p2) =>
        p1.startTime.compareTo(p2.startTime));
    return result;
  }

  List<Protocol> getCurrentDayProtocols() {
    if (selectedDay == null) return [];
    return getProtocolsByDay(selectedDay!);
  }

  @override
  void onDeviceDisconnected() {
    // TODO(alex): implement logic onDeviceDisconnected if needed
  }

  @override
  void onDeviceReconnected() {
    // TODO(alex): implement logic onDeviceReconnected if need
  }

}