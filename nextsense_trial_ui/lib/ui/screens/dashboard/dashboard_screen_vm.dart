import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
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

  DateTime? selectedDay;

  List<ScheduledProtocol> scheduledProtocols = [];

  // List of days that will appear for current study
  List<DateTime>? _days;

  void init() async {
    super.init();

    // TODO(alex): cache assessments (move to protocol manager?)
    scheduledProtocols = await _studyManager.loadScheduledProtocols();
    final int studyDays = getCurrentStudy()?.getDurationDays() ?? 0;
    _days = List<DateTime>.generate(studyDays, (i) =>
        _studyManager.currentStudyStartDate.add(Duration(days: i)));

    // TODO(alex): if current day out of range show some warning
    selectFirstDayOfStudy();
    notifyListeners();
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

  List<ScheduledProtocol> getScheduledProtocolsByDay(DateTime day) {
    List<ScheduledProtocol> result = [];
    for (var scheduledProtocol in scheduledProtocols) {
      if (scheduledProtocol.protocol != null
          && scheduledProtocol.day.isAtSameMomentAs(day)) {
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