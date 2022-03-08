import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreenViewModel extends ChangeNotifier {

  final CustomLogPrinter _logger = CustomLogPrinter('DashBoardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  DateTime? selectedDay;

  List<Assessment> assesments = [];

  // List of days that will appear for current study
  List<DateTime>? _days;

  void init() async {
    //selectToday();
    // TODO(alex): cache assessments (move to protocol manager?)
    assesments = await _studyManager.loadAssesments();
    for (var assesment in assesments) {
      print('[TODO] DashboardScreenViewModel.init ${assesment.id} ${assesment.dayNumber}');
    }
    print('[TODO] DashboardScreenViewModel.init ${_studyManager.currentStudyStartDate}');
    if (_studyManager.currentStudyStartDate != null) {
      final studyDays = getCurrentStudy()?.getDurationDays() ?? 0;
      _days = List<DateTime>.generate(studyDays, (i) =>
          _studyManager.currentStudyStartDate.add(Duration(days: i)));
      print('[TODO] DashboardScreenViewModel days loaded - $_days');
    }
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
    return result;
  }

  List<Protocol> getCurrentDayProtocols() {
    if (selectedDay == null) return [];
    return getProtocolsByDay(selectedDay!);
  }



}