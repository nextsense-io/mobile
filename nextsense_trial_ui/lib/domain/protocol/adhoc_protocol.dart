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

  AdhocProtocolRecord? record;

  RunnableProtocolType get type => RunnableProtocolType.adhoc;

  String? get lastSessionId => record?.getSession() ?? null;

  List<Survey>? get postSurveys => getPostProtocolSurveys();

  AdhocProtocol(ProtocolType protocolType, String studyId) :
        _studyId = studyId {
    protocol = Protocol(protocolType);
  }

  @override
  Future<bool> update(
      {required ProtocolState state, String? sessionId, bool persist = true}) async {
    _logger.log(Level.WARNING, 'Protocol state changing from ${this.state} to $state');

    this.state = state;

    if (sessionId == null) {
      // Don't persist adhoc protocol without session id
      return false;
    }

    if (record != null) {
      // Adhoc protocol record already exists, update its values
      record!
        ..setState(state)
        ..setSession(sessionId);
      return await record!.save();
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
      record = AdhocProtocolRecord(firebaseEntity);
      record!..setTimestamp(now)
        ..setSession(sessionId)
        ..setProtocol(protocol.name);
      return await record!.save();
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