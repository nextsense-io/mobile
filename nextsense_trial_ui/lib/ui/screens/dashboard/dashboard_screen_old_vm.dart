import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

class DashboardScreenOldViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DataManager _dataManager = getIt<DataManager>();

  List<ScheduledProtocol> get scheduledProtocols => _studyManager.scheduledProtocols;

  List<ScheduledSurvey> get scheduledSurveys => _surveyManager.scheduledSurveys;

  List<StudyDay> get _days => _studyManager.days;

  bool? get studyInitialized => _studyManager.studyInitialized;

  String get studyId => _studyManager.currentStudyId!;

  // Returns current day of study
  StudyDay? get _today => _studyManager.today;

  // Current selected day in calendar
  StudyDay? selectedDay;
  int get selectedDayNumber => selectedDay?.dayNumber ?? 0;

  late Timer _protocolCheckTimer;

  final studyDayChangeStream = StreamController<int>.broadcast();

  @override
  void init() async {
    super.init();

    await loadData();

    _initProtocolCheckTimer();
    _checkScheduledEntitiesTimeConstraints();
  }

  Future loadData() async {
    clearErrors();
    notifyListeners();
    setBusy(true);
    try {
      if (!_dataManager.userStudyDataLoaded) {
        bool success = await _dataManager.loadUserData();
        if (!success) {
          _logger.log(Level.WARNING, 'Failed to load user. Fallback to signup');
          logout();
          return;
        }
      }
    } catch (e, stacktrace) {
      _logger.log(Level.SEVERE, 'Failed to load dashboard data: ${e.toString()}, '
          '${stacktrace.toString()}');
      setError("Failed to load data. Please contact support");
      setBusy(false);
      return;
    }
    setBusy(false);
    StudyDay? studyDay = _studyManager.today;
    if (studyDay != null) {
      selectDay(_studyManager.today!);
    } else {
      if (DateTime.now().isAfter(_studyManager.currentStudyEndDate!)) {
        selectDay(_studyManager.days.last);
      } else {
        selectDay(_studyManager.days.first);
      }
    }
  }

  void _initProtocolCheckTimer() {
    _protocolCheckTimer = Timer.periodic(
      Duration(seconds: 1), (_) {
        // Only execute beginning of each minute
        if (DateTime.now().second != 0) return;
        _checkScheduledEntitiesTimeConstraints();
      },
    );
  }

  // Find and skip scheduled protocols/surveys that user didn't start at desired time window.
  void _checkScheduledEntitiesTimeConstraints() {
    for (final scheduledProtocol in scheduledProtocols) {
      if (scheduledProtocol.isLate()) {
        // This can run again so not a big problem if fails once, no need to check.
        scheduledProtocol.update(state: ProtocolState.skipped);
      }
    }
    for (final scheduledSurvey in scheduledSurveys) {
      if (scheduledSurvey.isLate()) {
        // This can run again so not a big problem if fails once, no need to check.
        scheduledSurvey.update(state: SurveyState.skipped);
      }
    }

    notifyListeners();
  }

  Study? getCurrentStudy() {
    return _studyManager.currentStudy;
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

  List<ScheduledProtocol> getScheduledProtocolsByDay(StudyDay day) {
    List<ScheduledProtocol> result = [];
    for (var scheduledProtocol in scheduledProtocols) {
      if (scheduledProtocol.day == day) {
        result.add(scheduledProtocol);
      }
    }
    result.sort((p1, p2) => p1.startTime.compareTo(p2.startTime));
    return result;
  }

  bool dayHasAnyScheduledProtocols(StudyDay day) {
    return getScheduledProtocolsByDay(day).isNotEmpty;
  }

  List<ScheduledProtocol> getCurrentDayScheduledProtocols() {
    if (selectedDay == null) return [];
    return getScheduledProtocolsByDay(selectedDay!);
  }

  List<ScheduledSurvey> getCurrentDayScheduledSurveys() {
    if (selectedDay == null) return [];
    return getScheduledSurveysByDay(selectedDay!);
  }

  List<ScheduledSurvey> getScheduledSurveysByDay(StudyDay day) {
    List<ScheduledSurvey> result = [];
    for (var scheduledSurvey in scheduledSurveys) {
      if (scheduledSurvey.day == day) {
        result.add(scheduledSurvey);
      }
    }
    return result;
  }

  SurveyStats getScheduledSurveyStats(ScheduledSurvey scheduledSurvey) {
    return _surveyManager.getScheduledSurveyStats(scheduledSurvey);
  }

  List<AdhocProtocol> getAdhocProtocols() {
    List<ProtocolType> allowedProtocols = _studyManager.currentStudy!.getAllowedProtocols();

    return allowedProtocols.map((protocolType) => AdhocProtocol(
        protocolType, _studyManager.currentStudyId!)).toList();
  }

  List<Survey> getAdhocSurveys() {
    List<String> adhocSurveyIds = _studyManager.currentStudy!.getAllowedSurveys();

    List<Survey> result = [];
    for (var surveyId in adhocSurveyIds) {
      Survey? survey = _surveyManager.getSurveyById(surveyId);
      if (survey == null) {
        _logger.log(Level.WARNING, 'Survey with id "$surveyId" not found');
        continue;
      }
      result.add(survey);
    }
    return result;
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