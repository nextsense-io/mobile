import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';

// Class to represents protocol running and track its state
abstract class RunnableProtocol {

  late Protocol protocol;

  ScheduleType get scheduleType;
  ProtocolState get state;
  String? get lastSessionId;
  DocumentReference? get reference;

  Future<bool> update({required ProtocolState state, String? sessionId, bool persist = true});
}