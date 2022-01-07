import 'package:get_it/get_it.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/domain/data_session.dart';
import 'package:nextsense_trial_ui/domain/session.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

enum Modality {
  eeeg,
}

class SessionManager {
  static final int _firstSessionNumber = 1;

  final FirestoreManager _firestoreManager =
      GetIt.instance.get<FirestoreManager>();
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();

  Session? _currentSession;
  DataSession? _currentDataSession;

  Future<bool> startSession(String deviceMacAddress) async {
    String? userCode = _authManager.getUserCode();
    if (userCode == null) {
      return false;
    }
    User? userEntity = _authManager.getUserEntity();
    if (userEntity == null) {
      return false;
    }
    int? sessionNumber = userEntity.getValue(UserKey.session_number);
    int nextSessionNumber =
        sessionNumber == null ? _firstSessionNumber : sessionNumber + 1;
    String sessionCode = userCode + '_sess_' + nextSessionNumber.toString();

    // Add the session.
    _currentSession = Session(await _firestoreManager.queryEntity(
        [Table.sessions], [sessionCode]));
    // TODO(eric): Add other values once the study logic is in place.
    DateTime startTime = DateTime.now();
    _currentSession!.setValue(
        SessionKey.start_datetime, startTime.toIso8601String());
    _currentSession!.setValue(SessionKey.user_id, userCode);
    await _firestoreManager.persistEntity(_currentSession!);

    // Add the data session.
    DataSession dataSessionEntity = DataSession(
        await _firestoreManager.queryEntity(
            [Table.sessions, Table.data_sessions],
            [sessionCode, Modality.eeeg.name]));
    dataSessionEntity.setValue(
        DataSessionKey.start_datetime, startTime.toIso8601String());
    // TODO(eric): Add an API to get this from the connected device.
    dataSessionEntity.setValue(DataSessionKey.streaming_rate, 250);
    await _firestoreManager.persistEntity(dataSessionEntity);

    // Update the session number in the user entry.
    userEntity.setValue(UserKey.session_number, nextSessionNumber);
    await _firestoreManager.persistEntity(userEntity);

    // TODO(eric): Start streaming should return the exact start time of the
    //             session, and then that should be persisted in the table?
    NextsenseBase.startStreaming(deviceMacAddress);
    return true;
  }

  Future stopSession(String deviceMacAddress) async {
    if (_currentSession == null || _currentDataSession == null) {
      return;
    }
    NextsenseBase.stopStreaming(deviceMacAddress);
    DateTime stopTime = DateTime.now();
    _currentSession!.setValue(SessionKey.end_datetime,
        stopTime.toIso8601String());
    await _firestoreManager.persistEntity(_currentSession!);
    _currentSession = null;
    _currentDataSession!.setValue(
        DataSessionKey.end_datetime, stopTime.toIso8601String());
    await _firestoreManager.persistEntity(_currentDataSession!);
    _currentDataSession = null;
  }
}