import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class AdhocProtocol implements RunnableProtocol {
  final CustomLogPrinter _logger = CustomLogPrinter('AdhocProtocol');

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final String _studyId;

  late Protocol protocol;
  ProtocolState state = ProtocolState.not_started;
  AdhocProtocolRecord? _record;

  RunnableProtocolType get type => RunnableProtocolType.adhoc;
  String? get lastSessionId => _record?.getSession() ?? null;
  List<Survey>? get postSurveys => getPostProtocolSurveys();

  AdhocProtocol(ProtocolType protocolType, String studyId) : _studyId = studyId {
    protocol = Protocol(protocolType);
  }

  AdhocProtocol.fromRecord(AdhocProtocolRecord record, String studyId) : _studyId = studyId {
    _record = record;
    protocol = Protocol(record.getProtocolType());
    state = record.getState();
  }

  @override
  Future<bool> update(
      {required ProtocolState state, String? sessionId, bool persist = true}) async {
    _logger.log(Level.WARNING, 'Protocol state changing from ${this.state} to $state');

    this.state = state;

    if (_record == null && sessionId == null) {
      // Don't persist adhoc protocol without a session id.
      return false;
    }

    if (_record != null) {
      // Adhoc protocol record already exists, update its values
      _record!.setState(state);
      if (sessionId != null) {
        _record!.setSession(sessionId);
      }
      return await _record!.save();
    } else {
      // Create new record
      DateTime now = DateTime.now();
      String adhocProtocolKey = "${protocol.name}_${now.millisecondsSinceEpoch}";
      FirebaseEntity? firebaseEntity = await _firestoreManager.queryEntity([
        Table.users,
        Table.enrolled_studies,
        Table.adhoc_protocols
      ], [
        _authManager.userCode!,
        _studyId,
        adhocProtocolKey
      ]);
      if (firebaseEntity == null) {
        return false;
      }
      _record = AdhocProtocolRecord(firebaseEntity);
      _record!..setTimestamp(now)
        ..setState(state)
        ..setSession(sessionId!)
        ..setProtocol(protocol.name);
      return await _record!.save();
    }
  }

  List<Survey> getPostProtocolSurveys() {
    List<Survey> surveys = [];
    for (String surveyId in protocol.postRecordingSurveys) {
      Survey? survey = _surveyManager.getSurveyById(surveyId);
      if (survey == null) {
        _logger.log(Level.SEVERE, "Survey ${surveyId} not found.");
        continue;
      }
      surveys.add(survey);
    }
    return surveys;
  }

  @override
  DocumentReference? get reference => _record?.reference;
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

  DateTime? getTimestamp() {
    final timestampString = getValue(AdhocProtocolRecordKey.timestamp);
    return timestampString != null ? (timestampString as Timestamp).toDate() : null;
  }

  void setTimestamp(DateTime timestamp) {
    setValue(AdhocProtocolRecordKey.timestamp, timestamp.toIso8601String());
  }

  ProtocolState getState() {
    return protocolStateFromString(getValue(AdhocProtocolRecordKey.status));
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

  ProtocolType getProtocolType() {
    return protocolTypeFromString(getValue(AdhocProtocolRecordKey.protocol));
  }

  void setProtocol(String protocolName) {
    setValue(AdhocProtocolRecordKey.protocol, protocolName);
  }
}