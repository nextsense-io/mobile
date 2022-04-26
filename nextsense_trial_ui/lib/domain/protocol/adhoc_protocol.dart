import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class AdhocProtocol implements RunnableProtocol {
  final CustomLogPrinter _logger = CustomLogPrinter('AdhocProtocol');

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final String _studyId;

  late Protocol protocol;

  ProtocolState state = ProtocolState.not_started;

  AdhocProtocolRecord? record;

  RunnableProtocolType get type => RunnableProtocolType.adhoc;

  String? get lastSessionId => record?.getSession() ?? null;

  AdhocProtocol(ProtocolType protocolType, String StudyId) :
        _studyId = StudyId {
    protocol = Protocol(protocolType);
  }

  @override
  bool update(
      {required ProtocolState state, String? sessionId, bool persist = true}) {
    _logger.log(
        Level.WARNING, 'Protocol state changing from ${this.state} to $state');

    this.state = state;

    if (sessionId == null) {
      // Don't persist adhoc protocol without session id
      return false;
    }

    if (record != null) {
      // Adhoc protocol record already exists, update its values
      record!
        ..setState(state)
        ..setSession(sessionId)
        ..save();
    } else {
      // Create new record
      DateTime now = DateTime.now();
      String adhocProtocolKey = "${protocol.name}_${now.millisecondsSinceEpoch}";
      _firestoreManager.queryEntity([
        Table.users,
        Table.enrolled_studies,
        Table.adhoc_protocols
      ], [
        _authManager.getUserCode()!,
        _studyId,
        adhocProtocolKey
      ]).then((firebaseEntity) {
        record = AdhocProtocolRecord(firebaseEntity);
        record!..setTimestamp(now)
          ..setSession(sessionId)
          ..setProtocol(protocol.name)
          ..save();
      });
    }
    return true;
  }
}

enum AdhocProtocolRecordKey {
  protocol,
  timestamp,
  session,
  status
}

class AdhocProtocolRecord extends FirebaseEntity<AdhocProtocolRecordKey> {

  AdhocProtocolRecord(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  void setTimestamp(DateTime timestamp) {
    setValue(AdhocProtocolRecordKey.timestamp, timestamp.toIso8601String());
  }

  // Set state of protocol in firebase
  void setState(ProtocolState state) {
    setValue(AdhocProtocolRecordKey.status, state.name);
  }

  void setSession(String sessionId) {
    setValue(AdhocProtocolRecordKey.session, sessionId);
  }

  String? getSession() {
    return getValue(AdhocProtocolRecordKey.session);
  }

  void setProtocol(String protocolName) {
    setValue(AdhocProtocolRecordKey.protocol, protocolName);
  }
}