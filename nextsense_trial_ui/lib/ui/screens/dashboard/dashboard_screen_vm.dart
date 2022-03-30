import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  List<ScheduledProtocol> scheduledProtocols = [];

  // List of days that will appear for current study
  List<StudyDay>? _days;

  StudyDay _today = StudyDay(DateTime.now());
  StudyDay? selectedDay;

  void init() async {
    super.init();

    // TODO(alex): cache assessments (move to protocol manager?)
    scheduledProtocols = await _studyManager.loadScheduledProtocols();
    final int studyDays = getCurrentStudy()?.getDurationDays() ?? 0;
    _days = List<StudyDay>.generate(studyDays, (i) {
      DateTime dayDate = _studyManager.currentStudyStartDate
          .add(Duration(days: i));
      return StudyDay(dayDate);
    });

    // TODO(alex): if current day out of range show some warning

    // Select current day
    selectDay(_today);

    //selectFirstDayOfStudy();
    //notifyListeners();
  }

  Study? getCurrentStudy() {
    return _studyManager.getCurrentStudy();
  }

  List<StudyDay> getDays() {
    return _days ?? [];
  }

  void selectDay(StudyDay day) {
    selectedDay = day;
    notifyListeners();
  }

  void selectFirstDayOfStudy() {
    if (_days != null)
      selectDay(_days![0]);
  }

  List<ScheduledProtocol> getScheduledProtocolsByDay(StudyDay day) {
    List<ScheduledProtocol> result = [];
    for (var scheduledProtocol in scheduledProtocols) {
      if (scheduledProtocol.day == day) {
        result.add(scheduledProtocol);
      }
    }
    result.sort((p1, p2) =>
        p1.startTime.compareTo(p2.startTime));
    return result;
  }

  List<ScheduledProtocol> getCurrentDayScheduledProtocols() {
    if (selectedDay == null) return [];
    return getScheduledProtocolsByDay(selectedDay!);
  }

  @override
  void onDeviceDisconnected() {
    // TODO(alex): implement logic onDeviceDisconnected if needed
  }

  @override
  void onDeviceReconnected() {
    // TODO(alex): implement logic onDeviceReconnected if need
  }

  void disconnectDevice() {
    _deviceManager.disconnectDevice();
  }

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
  }
}