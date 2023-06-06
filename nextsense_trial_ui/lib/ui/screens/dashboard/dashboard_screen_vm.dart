import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/medication/planned_medication.dart';
import 'package:nextsense_trial_ui/domain/medication/scheduled_medication.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/session/scheduled_session.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/medication_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

class DashboardScreenViewModel extends DeviceStateViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('DashboardScreenViewModel');

  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final MedicationManager _medicationManager = getIt<MedicationManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final studyDayChangeStream = StreamController<int>.broadcast();

  bool? get studyInitialized => _studyManager.studyScheduled;
  // Returns current day of study
  StudyDay? get today => _studyManager.today;
  List<ScheduledSession> get scheduledSessions => _studyManager.scheduledSessions;
  List<ScheduledSurvey> get scheduledSurveys => _surveyManager.scheduledSurveys;
  List<ScheduledMedication> get scheduledMedications => _medicationManager.scheduledMedications;
  List<PlannedMedication> get plannedMedications => _medicationManager.plannedMedications;
  String get studyId => _studyManager.currentStudyId!;
  String get studyName => _studyManager.currentStudy!.getName();
  String get studyDescription => _studyManager.currentStudy!.getDescription();
  String get studyLengthDays => _studyManager.getStudyLength().inDays.toString();
  DateTime get studyStartDate => _studyManager.currentStudyStartDate!;
  String get completedSurveys => _surveyManager.getGlobalSurveyStats().completed.toString();
  Study get study =>_studyManager.currentStudy!;
  bool get studyStarted => _studyManager.isStudyStarted();
  bool get studyFinished => _studyManager.isStudyFinished();
  bool get studyHasAdhocProtocols => _studyManager.allowedAdhocProtocols.isNotEmpty;
  List<StudyDay> get _days => _studyManager.days;
  int get selectedDayNumber => selectedDay?.dayNumber ?? 0;

  // Current selected day in calendar
  StudyDay? selectedDay;

  @override
  void init() async {
    super.init();
    await loadData();
  }

  @override
  void dispose() {
    super.dispose();
    studyDayChangeStream.close();
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
    if (studyDay != null && _studyManager.currentStudyEndDate != null) {
      selectDay(_studyManager.today!);
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

  List<StudyDay> getDays() {
    return _days;
  }

  List<ScheduledSession> getScheduledProtocolsByDay(StudyDay day) {
    List<ScheduledSession> result = [];
    for (var scheduledSession in scheduledSessions) {
      if (scheduledSession.getStudyDay(
          _studyManager.currentEnrolledStudy!.getStartDate()!) == day.dayNumber) {
        result.add(scheduledSession);
      }
    }
    result.sort((p1, p2) => p1.startTime!.compareTo(p2.startTime!));
    return result;
  }

  List<ScheduledSession> getCurrentDayScheduledProtocols() {
    if (selectedDay == null) return [];
    return getScheduledProtocolsByDay(selectedDay!);
  }

  List<ScheduledSurvey> getCurrentDayScheduledSurveys() {
    if (selectedDay == null) return [];
    List<ScheduledSurvey> surveys =
        _getScheduledSurveysByDay(selectedDay!, period: Period.daily);
    surveys.addAll(_getScheduledSurveysByDay(selectedDay!, period: Period.specific_day));
    return surveys;
  }

  List<ScheduledMedication> getCurrentDayScheduledMedications() {
    if (selectedDay == null) return [];
    List<ScheduledMedication> medications =
    _getScheduledMedicationsByDay(selectedDay!, period: Period.daily);
    medications.addAll(_getScheduledMedicationsByDay(selectedDay!, period: Period.specific_day));
    return medications;
  }

  List<ScheduledSurvey> getCurrentWeekScheduledSurveys() {
    if (selectedDay == null) return [];
    return _getScheduledSurveysByDay(selectedDay!, period: Period.weekly);
  }

  List<ScheduledSurvey> _getScheduledSurveysByDay(StudyDay day, {Period? period}) {
    List<ScheduledSurvey> result = [];
    for (var scheduledSurvey in scheduledSurveys) {
      if (scheduledSurvey.day == day && (period == null || period == scheduledSurvey.period)) {
        result.add(scheduledSurvey);
      }
    }
    return result;
  }

  List<ScheduledMedication> _getScheduledMedicationsByDay(StudyDay day, {Period? period}) {
    List<ScheduledMedication> result = [];
    for (var scheduledMedication in scheduledMedications) {
      if (scheduledMedication.getStudyDay(_studyManager.currentStudyStartDate!) == day &&
          (period == null || period == scheduledMedication.period)) {
        result.add(scheduledMedication);
      }
    }
    return result;
  }

  SurveyStats getScheduledSurveyStats(ScheduledSurvey scheduledSurvey) {
    return _surveyManager.getScheduledSurveyStats(scheduledSurvey);
  }

  List<dynamic> getTodayTasks(TaskType taskType) {
    List<Task> allTasks = [];
    if (taskType == TaskType.recording || taskType == TaskType.any) {
      allTasks.addAll(getCurrentDayScheduledProtocols());
    }
    if (taskType == TaskType.survey || taskType == TaskType.any) {
      allTasks.addAll(getCurrentDayScheduledSurveys());
    }
    if (taskType == TaskType.medication || taskType == TaskType.any) {
      allTasks.addAll(getCurrentDayScheduledMedications());
    }
    return allTasks;
  }

  List<dynamic> getWeeklyTasks(TaskType taskType) {
    return getCurrentWeekScheduledSurveys();
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