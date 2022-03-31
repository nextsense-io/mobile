
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/assesment.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum ScheduledProtocolKey {
  protocol,
  sessions,
  status
}

class ScheduledProtocol extends FirebaseEntity<ScheduledProtocolKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledProtocol');
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  late StudyDay day;
  late DateTime startTime;
  late Protocol protocol;

  late DateTime allowedStartBefore;
  late DateTime allowedStartAfter;

  ProtocolState get state =>
      protocolStateFromString(getValue(ScheduledProtocolKey.status));

  bool get isCompleted => state == ProtocolState.completed;
  bool get isSkipped => state == ProtocolState.skipped;

  ScheduledProtocol(FirebaseEntity firebaseEntity, PlannedAssessment plannedAssessment) :
        super(firebaseEntity.getDocumentSnapshot()) {
    protocol = plannedAssessment.protocol!;
    day = StudyDay(plannedAssessment.day);
    startTime = plannedAssessment.startTime;
    // Substract 1 second to make sure isAfter method works
    // correct on beginning of each minute
    // i.e 11:00:00 is after 10:59:59
    allowedStartAfter = startTime
        .subtract(Duration(minutes: plannedAssessment.allowEarlyStartTimeMinutes));
    allowedStartBefore = startTime
        .add(Duration(minutes: plannedAssessment.allowLateStartTimeMinutes));
  }

  // Set state of protocol in firebase
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

  // Protocol is within desired window to start
  bool isAllowedToStart() {
    final now = DateTime.now();
    final currentTime = DateTime(0,0,0,now.hour, now.minute);
    return currentTime.isAfter(allowedStartAfter.subtract(Duration(seconds: 1)))
        && currentTime.isBefore(allowedStartBefore);
  }

  // Protocol didn't start in time, should be skipped
  bool isLate() {
    // Protocol is already finished, no need to change its state
    if ([ProtocolState.completed, ProtocolState.skipped].contains(state))
      return false;
    final now = DateTime.now();
    final currentTime = DateTime(0,0,0,now.hour, now.minute);
    return state == ProtocolState.not_started
        && currentTime.isAfter(allowedStartBefore.subtract(Duration(seconds: 1)));
  }

  // Update fields and save to firestore by default
  bool update({required ProtocolState state,
    String? sessionId, bool persist = true}) {
    if (this.state == ProtocolState.completed) {
      _logger.log(Level.INFO, 'Protocol ${protocol.name} already completed.'
          'Cannot change its state.');
      return false;
    }
    else if (this.state == ProtocolState.skipped) {
      _logger.log(Level.INFO, 'Protocol ${protocol.name} already skipped.'
          'Cannot change its state.');
      return false;
    }
    _logger.log(Level.WARNING,
        'Protocol state changing from ${this.state} to $state');
    setState(state);
    if (sessionId != null) {
      addSession(sessionId);
    }
    if (persist) {
      save();
    }
    return true;
  }

}