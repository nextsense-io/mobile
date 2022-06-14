import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

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
  String? get userId => _authManager.user?.id;

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

  void disconnectDevice() {
    _deviceManager.disconnectDevice();
  }

  void logout() {
    _deviceManager.disconnectDevice();
    _authManager.signOut();
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