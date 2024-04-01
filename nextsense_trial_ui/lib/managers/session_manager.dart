import 'package:flutter_common/domain/device_settings.dart';
import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/data_session.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/session.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/managers/trial_ui_firestore_manager.dart';
import 'package:nextsense_trial_ui/preferences.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum Modality {
  eeeg,
}

class SessionManager {
  final TrialUiFirestoreManager _firestoreManager = getIt<TrialUiFirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final Preferences _preferences = getIt<Preferences>();
  final CustomLogPrinter _logger = CustomLogPrinter('SessionManager');

  Session? _currentSession;
  Session? _lastSession;
  DataSession? _currentDataSession;
  String? get currentSessionId => _currentSession?.id;
  int? _currentLocalSession;
  String? _appName;
  String? _appVersion;

  SessionManager() {
    _init();
  }

  void _init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appName = packageInfo.appName;
    _appVersion = packageInfo.version;
  }

  Future<bool> startSession({required Device device, required String studyId,
      required plannedSessionId, required String protocolName, String? scheduledSessionId}) async {
    User? user = _authManager.user;
    if (user == null) {
      return false;
    }
    if (!await NextsenseBase.canStartNewSession()) {
      _logger.log(Level.INFO, "Cannot start new session. Another session is already in progress.");
      return false;
    }

    // Add the session.
    FirebaseEntity? sessionEntity =
        await _firestoreManager.addAutoIdEntity([Table.sessions], []);
    _currentSession = Session(sessionEntity);
    DateTime startTime = DateTime.now();

    _logger.log(Level.INFO, "Starting session with device: ${device.name} of type: ${device.type}");
    String? earbudsConfig;
    switch (device.type) {
      case DeviceType.kauai_medical:
        earbudsConfig = EarbudsConfigNames.KAUAI_MEDICAL_CONFIG.name.toLowerCase();
        break;
      case DeviceType.nitro:
        earbudsConfig = EarbudsConfigNames.NITRO_CONFIG.name.toLowerCase();
        break;
      case DeviceType.kauai:
        earbudsConfig = EarbudsConfigNames.XENON_P02_CONFIG.name.toLowerCase();
        break;
      default:
        earbudsConfig = _studyManager.currentStudy?.getEarbudsConfig() ??
            EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase();
        break;
    }

    _currentSession!..setValue(SessionKey.start_datetime, startTime)
                    ..setValue(SessionKey.scheduled_session_id, scheduledSessionId)
                    ..setValue(SessionKey.planned_session_id, plannedSessionId)
                    ..setValue(SessionKey.user_id, user.id)
                    ..setValue(SessionKey.device_id, device.name)
                    ..setValue(SessionKey.device_mac_address, device.macAddress)
                    ..setValue(SessionKey.earbud_config, earbudsConfig)
                    ..setValue(SessionKey.study_id, studyId)
                    ..setValue(SessionKey.mobile_app_version, _appVersion)
                    ..setValue(SessionKey.protocol_name, protocolName)
                    ..setValue(SessionKey.timezone, user.getCurrentTimezone().name);

    bool success = await _currentSession!.save();
    if (!success) {
      return false;
    }

    // Add the data session.
    FirebaseEntity? dataSessionEntity = await _firestoreManager.addAutoIdEntity(
        [Table.sessions, Table.data_sessions],
        [_currentSession!.id]);
    _currentDataSession = DataSession(dataSessionEntity);
    _currentDataSession!.setValue(DataSessionKey.name, Modality.eeeg.name);
    _currentDataSession!.setValue(DataSessionKey.start_datetime, startTime);
    // TODO(eric): Add an API to get this from the connected device.
    DeviceSettings deviceSettings =
        DeviceSettings(await NextsenseBase.getDeviceSettings(device.macAddress));
    _currentDataSession!.setValue(DataSessionKey.streaming_rate, deviceSettings.eegStreamingRate);
    success = await _currentDataSession!.save();
    if (!success) {
      return false;
    }

    // Update the session number in the user entry.
    user.setValue(UserKey.session_number, user.getValue(UserKey.session_number) ?? 0 + 1);
    success = await user.save();
    if (!success) {
      return false;
    }

    // TODO(eric): Start streaming should return the exact start time of the session, and then that
    //             should be persisted in the table?
    try {
      _logger.log(Level.INFO, "Recording with continuous impedance: "
          "${_preferences.getBool(PreferenceKey.continuousImpedance)}");
      ImpedanceMode impedanceMode = ImpedanceMode.OFF;
      if (_preferences.getBool(PreferenceKey.continuousImpedance)) {
        impedanceMode = ImpedanceMode.ON_1299_AC;
      }
      bool configSet = await NextsenseBase.setImpedanceConfig(device.macAddress, impedanceMode,
          /*channelNumber=*/null, /*frequencyDivider=*/null);
      _logger.log(Level.INFO, "Impedance config set: $configSet");
      if (!configSet) {
        _logger.log(Level.SEVERE, "Failed to set impedance config. Cannot start streaming.");
        return false;
      }

      _currentLocalSession = await _deviceManager.startStreaming(uploadToCloud: true,
          bigTableKey: user.getValue(UserKey.bt_key), dataSessionCode: _currentSession!.id,
          earbudsConfig: earbudsConfig,
          saveToCsv: _preferences.getBool(PreferenceKey.saveBleDataToLocalCsv));
      _logger.log(Level.INFO, "Started streaming with local session: $_currentLocalSession and "
          "earbuds config: $earbudsConfig");
      await NextsenseBase.changeNotificationContent("NextSense recording in progress",
          "Press to access the application");
      return true;
    } catch (exception) {
      _logger.log(Level.SEVERE, "Failed to start streaming. Message: $exception");
    }
    return false;
  }

  Session? getCurrentSession() {
    return _currentSession;
  }

  // Check in the user record if there is a running session, then load it.
  Future<Session?> loadCurrentSession() async {
    _logger.log(Level.INFO, 'Checking if need to load a current session.');
    User? user = _authManager.user;
    if (user == null) {
      return null;
    }
    RunnableProtocol? runningProtocol = await user.getRunningProtocol(
        _studyManager.currentStudyStartDate, _studyManager.currentStudyEndDate);
    if (runningProtocol != null) {
      _logger.log(Level.INFO, 'Running sessions, load ${runningProtocol.lastSessionId}');
      FirebaseEntity? sessionEntity =
          await _firestoreManager.queryEntity([Table.sessions], [runningProtocol.lastSessionId!]);
      if (sessionEntity != null) {
        FirebaseEntity? dataSessionEntity = await _firestoreManager.queryEntity(
            [Table.sessions, Table.data_sessions],
            [sessionEntity.id, Modality.eeeg.name]);
        if (dataSessionEntity != null) {
          _currentSession = Session(sessionEntity);
          _currentDataSession = DataSession(dataSessionEntity);
          return _currentSession;
        }
      }
    }
    return null;
  }

  Future stopSession(String deviceMacAddress) async {
    if (_currentSession == null || _currentDataSession == null) {
      _logger.log(Level.WARNING, 'Tried to stop a session while none was running.');
      return;
    }
    try {
      _deviceManager.stopStreaming();
    } catch (exception) {
      _logger.log(Level.SEVERE, 'Failed to stop streaming. Message: $exception');
    }
    DateTime stopTime = DateTime.now();
    _currentSession!.setValue(SessionKey.end_datetime, stopTime);
    await _currentSession!.save();
    _lastSession = _currentSession;
    _currentSession = null;
    _currentDataSession!.setValue(DataSessionKey.end_datetime, stopTime);
    await _currentDataSession!.save();
    _currentDataSession = null;
    User? user = _authManager.user;
    if (user == null) {
      _logger.log(Level.WARNING, 'Could not get the user when stopping a session, the session '
          'might be marked as still running.');
      return;
    }
    user.setValue(UserKey.running_protocol, null);
    await user.save();
    await NextsenseBase.changeNotificationContent(_appName!, "Press to access the application");
  }

  Future<bool> addProtocolData(Map protocolData) async {
    if (_currentSession == null && _lastSession == null) {
      _logger.log(Level.WARNING, 'Tried to add info on a session while none was ran or running.');
      return false;
    }
    Session lastSession = _currentSession != null ? _currentSession! : _lastSession!;
    lastSession.setValue(SessionKey.protocol_data, protocolData);
    return await lastSession.save();
  }
}