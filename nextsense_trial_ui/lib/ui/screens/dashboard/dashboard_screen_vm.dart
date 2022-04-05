import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  List<ScheduledProtocol> scheduledProtocols = [];

  // TODO(alex): make scheduled surveys
  List<Survey> scheduledSurveys = [];

  // List of days that will appear for current study
  List<StudyDay>? _days;

  StudyDay _today = StudyDay(DateTime.now());
  StudyDay? selectedDay;

  late Timer _protocolCheckTimer;

  void init() async {
    super.init();

    await loadData();

    _initProtocolCheckTimer();
    _checkProtocolsTimeConstraints();
  }

  Future loadData() async {
    clearErrors();
    notifyListeners();
    setBusy(true);
    try {
      await _loadSchedule();
      await _loadSurveys();
    } catch (e) {
      _logger.log(Level.SEVERE,
          'Failed to load dashboard data: ${e.toString()}');
      setError("Failed to load data. Please contact support");
      setBusy(false);
      return;
    }
    setBusy(false);
    // TODO(alex): if current day out of range show some warning
    // Select current day
    selectDay(_today);
  }

  // Load schedule based on planned assesment
  Future _loadSchedule() async {
    scheduledProtocols = await _studyManager.loadScheduledProtocols();
    final int studyDays = getCurrentStudy()?.getDurationDays() ?? 0;
    _days = List<StudyDay>.generate(studyDays, (i) {
      DateTime dayDate = _studyManager.currentStudyStartDate
          .add(Duration(days: i));
      return StudyDay(dayDate);
    });
  }

  Future _loadSurveys() async {
    scheduledSurveys = await _surveyManager.loadSurveys();
  }

  void _initProtocolCheckTimer() {
    _protocolCheckTimer = Timer.periodic(
      Duration(seconds: 1), (_){
        // Only execute beginning of each minute
        if (DateTime.now().second != 0) return;
        _checkProtocolsTimeConstraints();
      },
    );
  }

  // Find and skip protocols that user didn't start at desired time window
  void _checkProtocolsTimeConstraints() {
    for (final scheduledProtocol in scheduledProtocols) {
      if (scheduledProtocol.isLate()) {
        scheduledProtocol.update(state: ProtocolState.skipped);
      }
    }
    notifyListeners();
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

  bool dayHasAnyScheduledProtocols(StudyDay day) {
    return getScheduledProtocolsByDay(day).isNotEmpty;
  }

  List<ScheduledProtocol> getCurrentDayScheduledProtocols() {
    if (selectedDay == null) return [];
    return getScheduledProtocolsByDay(selectedDay!);
  }

  List<Survey> getCurrentDaySurveys() {
    // TODO(alex): display scheduled surveys for current day
    return scheduledSurveys;
  }

  List<AdhocProtocol> getAdhocProtocols() {
    List<ProtocolType> allowedProtocols =
    _studyManager.getCurrentStudy()!.getAllowedProtocols();

    return allowedProtocols.map((protocolType) => AdhocProtocol(protocolType))
        .toList();
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

  @override
  void dispose() {
    _protocolCheckTimer.cancel();
    super.dispose();
  }



}