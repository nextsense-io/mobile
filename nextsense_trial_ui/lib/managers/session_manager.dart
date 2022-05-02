import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/data_session.dart';
import 'package:nextsense_trial_ui/domain/session.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum Modality {
  eeeg,
}

class SessionManager {
  static final int _firstSessionNumber = 1;

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SessionManager');

  Session? _currentSession;
  DataSession? _currentDataSession;
  String? get currentSessionId => _currentSession?.id;
  int? _currentLocalSession;

  Future<bool> startSession(String deviceMacAddress, String studyId,
      String protocolName) async {
    String? userCode = _authManager.userCode;
    if (userCode == null) {
      return false;
    }
    User? user = _authManager.user;
    if (user == null) {
      return false;
    }
    int? sessionNumber = user.getValue(UserKey.session_number);
    int nextSessionNumber =
        sessionNumber == null ? _firstSessionNumber : sessionNumber + 1;
    String sessionCode = userCode + '_sess_' + nextSessionNumber.toString();

    // Add the session.
    _currentSession = Session(await _firestoreManager.queryEntity(
        [Table.sessions], [sessionCode]));
    DateTime startTime = DateTime.now();
    _currentSession!..setValue(
        SessionKey.start_datetime, startTime.toIso8601String())
                    ..setValue(SessionKey.user_id, userCode)
                    ..setValue(SessionKey.study_id, studyId)
                    ..setValue(SessionKey.protocol, protocolName);
    await _currentSession!.save();

    // Add the data session.
    _currentDataSession = DataSession(
        await _firestoreManager.queryEntity(
            [Table.sessions, Table.data_sessions],
            [sessionCode, Modality.eeeg.name]));
    _currentDataSession!.setValue(
        DataSessionKey.start_datetime, startTime.toIso8601String());
    // TODO(eric): Add an API to get this from the connected device.
    Map<String, dynamic> deviceSettings =
        await NextsenseBase.getDeviceSettings(deviceMacAddress);
    _currentDataSession!.setValue(DataSessionKey.streaming_rate,
        deviceSettings[describeEnum(DeviceSettingsFields.eegStreamingRate)]
            .value);
    await _currentDataSession!.save();

    // Update the session number in the user entry.
    user.setValue(UserKey.session_number, nextSessionNumber);
    await user.save();

    // TODO(eric): Start streaming should return the exact start time of the
    //             session, and then that should be persisted in the table?
    String dataSessionCode = sessionCode + '_' + Modality.eeeg.name;
    _currentLocalSession = await NextsenseBase.startStreaming(
        deviceMacAddress, /*uploadToCloud=*/true,
        user.getValue(UserKey.bt_key), dataSessionCode,
        _studyManager.currentStudy?.getEarbudsConfig() ?? null);

    return true;
  }

  Session? getCurrentSession() {
    return _currentSession;
  }

  Future stopSession(String deviceMacAddress) async {
    if (_currentSession == null || _currentDataSession == null) {
      _logger.log(Level.WARNING,
          'Tried to stop a session while none was running.');
      return;
    }
    NextsenseBase.stopStreaming(deviceMacAddress);
    DateTime stopTime = DateTime.now();
    _currentSession!.setValue(SessionKey.end_datetime,
        stopTime.toIso8601String());
    await _currentSession!.save();
    _currentSession = null;
    _currentDataSession!.setValue(
        DataSessionKey.end_datetime, stopTime.toIso8601String());
    await _currentDataSession!.save();
    _currentDataSession = null;
  }
}