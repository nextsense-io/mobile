import 'package:flutter_common/managers/device_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/planned_session.dart';
import 'package:nextsense_trial_ui/domain/session/adhoc_session.dart';
import 'package:nextsense_trial_ui/domain/survey/adhoc_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/planned_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreenViewModel extends DeviceStateViewModel {

  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ProfileScreenViewModel');

  String? get currentStudyName => _studyManager.currentStudy!.getName();
  bool get isAdhocRecordingAllowed => _studyManager.currentStudy?.adhocRecordingAllowed ?? false;
  bool get isAdhocSurveysAllowed => _studyManager.currentStudy?.adhocSurveysAllowed ?? false;
  String get studyId => _studyManager.currentStudyId!;
  String? get userId => _authManager.user!.getEmail() ?? _authManager.user!.getUsername()!;
  String? version = '';

  @override
  void init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    setInitialised(true);
    notifyListeners();
  }

  List<AdhocSession> getAdhocProtocols() {
    List<PlannedSession> allowedProtocols = _studyManager.allowedAdhocProtocols;

    return allowedProtocols.map((allowedProtocol) => AdhocSession(
        allowedProtocol.protocol!.type, allowedProtocol.id, _studyManager.currentStudyId!))
        .toList();
  }

  Map<PlannedSurvey, Survey> getAdhocSurveys() {
    // get planned and survey to view.
    List<PlannedSurvey> adhocPlannedSurveys = _surveyManager.allowedAdhocSurveys;

    Map<PlannedSurvey, Survey> result = {};
    for (var plannedSurvey in adhocPlannedSurveys) {
      Survey? survey = _surveyManager.getSurveyById(plannedSurvey.surveyId);
      if (survey == null) {
        _logger.log(Level.WARNING, 'Survey with id "${plannedSurvey.surveyId}" not found');
        continue;
      }
      result[plannedSurvey] = survey;
    }
    return result;
  }

  Future<AdhocSurvey> getAdhocRunnableSurvey(PlannedSurvey plannedSurvey) async {
    return await _surveyManager.createAdhocSurvey(plannedSurvey);
  }

  Future disconnectDevice() async {
    await _deviceManager.manualDisconnect();
    await _authManager.user!..setLastPairedDeviceMacAddress(null)..save();
    notifyListeners();
  }

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void onDeviceDisconnected() {
    // TODO(eric): implement onDeviceDisconnected
  }

  @override
  void onDeviceReconnected() {
    // TODO(eric): implement onDeviceReconnected
  }
}