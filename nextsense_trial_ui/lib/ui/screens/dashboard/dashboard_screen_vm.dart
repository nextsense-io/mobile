import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DashboardScreenViewModel extends ChangeNotifier {

  final CustomLogPrinter _logger = CustomLogPrinter('DashBoardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  DateTime? selectedDay;

  // Generates list of days [today,+1,+2,... +30]
  final days = List<DateTime>.generate(30, (i) =>
      DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).add(Duration(days: i)));

  Study? getStudy() {
      return _studyManager.getCurrentStudy();
  }

  List<DateTime> getDays() {
    return days;
  }

  void selectDay(DateTime day) {
    selectedDay = day;
    notifyListeners();
  }

  void selectToday() {
    selectDay(days[0]);
  }

  List<Protocol> getProtocols() {
    // TODO(alex): return protocols from db
    return [
      VariableDaytimeProtocol(),
      VariableDaytimeProtocol(),
      VariableDaytimeProtocol(),
    ];
  }

  List<Protocol> getCurrentDayProtocols() {
    return getProtocols();
  }

}