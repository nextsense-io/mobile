import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';

enum RunnableProtocolType {
  scheduled,
  adhoc
}

// Class to represents protocol running and track its state
abstract class RunnableProtocol {

  late Protocol protocol;

  RunnableProtocolType get type;
  ProtocolState get state;
  String? get lastSessionId;
  List<Survey>? get postSurveys;
  DocumentReference? get reference;

  Future<bool> update({required ProtocolState state, String? sessionId, bool persist = true});
}