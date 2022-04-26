import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';

enum RunnableProtocolType {
  scheduled,
  adhoc
}

// Class to represents protocol running and track its state
abstract class RunnableProtocol {
  late Protocol protocol;

  RunnableProtocolType get type;

  String? get lastSessionId;

  bool update({required ProtocolState state, String? sessionId,
    bool persist = true});
}