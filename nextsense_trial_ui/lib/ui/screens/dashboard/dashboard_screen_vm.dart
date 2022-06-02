import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final studyDayChangeStream = StreamController<int>.broadcast();

  bool? get studyInitialized => _studyManager.studyInitialized;
  // Returns current day of study
  StudyDay? get today => _studyManager.today;
  List<ScheduledProtocol> get scheduledProtocols => _studyManager.scheduledProtocols;
  List<ScheduledSurvey> get scheduledSurveys => _surveyManager.scheduledSurveys;
  String get studyId => _studyManager.currentStudyId!;
  String get studyName => _studyManager.currentStudy!.getName();
  String get studyDescription => _studyManager.currentStudy!.getDescription();
  String get studyLengthDays => _studyManager.getStudyLength().inDays.toString();
  String get completedSurveys => _surveyManager.getGlobalSurveyStats().completed.toString();
  bool get studyStarted => _studyManager.isStudyStarted();
  bool get studyFinished => _studyManager.isStudyFinished();

  // Current selected day in calendar
  StudyDay? selectedDay;

  void init() async {
    super.init();

    await loadData();
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

  void selectDay(StudyDay day) {
    selectedDay = day;
    notifyListeners();
    studyDayChangeStream.sink.add(day.dayNumber);
  }

  void selectToday() {
    if (today != null) {
      selectDay(today!);
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

  List<ScheduledProtocol> getCurrentDayScheduledProtocols() {
    if (selectedDay == null) return [];
    return getScheduledProtocolsByDay(selectedDay!);
  }

  List<ScheduledSurvey> getCurrentDayScheduledSurveys() {
    if (selectedDay == null) return [];
    List<ScheduledSurvey> surveys =
        _getScheduledSurveysByDay(selectedDay!, period: SurveyPeriod.daily);
    surveys.addAll(_getScheduledSurveysByDay(selectedDay!, period: SurveyPeriod.specific_day));
    return surveys;
  }

  List<ScheduledSurvey> getCurrentWeekScheduledSurveys() {
    if (selectedDay == null) return [];
    return _getScheduledSurveysByDay(selectedDay!, period: SurveyPeriod.weekly);
  }

  List<ScheduledSurvey> _getScheduledSurveysByDay(StudyDay day, {SurveyPeriod? period}) {
    List<ScheduledSurvey> result = [];
    for (var scheduledSurvey in scheduledSurveys) {
      if (scheduledSurvey.day == day && (period == null || period == scheduledSurvey.period)) {
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

  List<dynamic> getTodayTasks() {
    List<Task> protocols = getCurrentDayScheduledProtocols();
    List<Task> surveys = getCurrentDayScheduledSurveys();
    List<Task> allTasks = [];
    allTasks.addAll(protocols);
    allTasks.addAll(surveys);
    return allTasks;
  }

  List<dynamic> getWeeklyTasks() {
    return getCurrentWeekScheduledSurveys();
  }

  void disconnectDevice() {
    _deviceManager.disconnectDevice();
  }

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
  }

  @override
  void onDeviceDisconnected() {
    // TODO(alex): implement logic onDeviceDisconnected if needed
  }

  @override
  void onDeviceReconnected() {
    // TODO(alex): implement logic onDeviceReconnected if needed
  }
}