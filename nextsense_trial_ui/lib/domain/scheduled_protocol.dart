
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum ScheduledProtocolKey {
  protocol,
  sessions,
  status
}

class ScheduledProtocol extends FirebaseEntity<ScheduledProtocolKey> {

  late DateTime day;
  late DateTime startTime;
  late Protocol protocol;

  ProtocolState get state =>
      protocolStateFromString(getValue(ScheduledProtocolKey.status));

  bool get isCompleted => state == ProtocolState.completed;

  ScheduledProtocol(FirebaseEntity firebaseEntity, PlannedAssessment plannedAssessment) :
        super(firebaseEntity.getDocumentSnapshot()) {
    this.protocol = plannedAssessment.protocol!;
    this.day = plannedAssessment.day;
    this.startTime = plannedAssessment.startTime;
  }

  // Set and persist state of protocol in firebase
  void setState(ProtocolState state) {
    setValue(ScheduledProtocolKey.status, state.name);
  }

  // Store session in array of sessions
  void addSession(String sessionId) {
    var currentSessionList = getValue(ScheduledProtocolKey.sessions);
    if (currentSessionList is List) {
      if (!currentSessionList.contains(sessionId)) {
        currentSessionList.add(sessionId);
      }
    } else
    {
      currentSessionList = <String>[sessionId];
    }

    setValue(ScheduledProtocolKey.sessions, currentSessionList);
  }

}