import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/runnable_protocol.dart';

class AdhocProtocol implements RunnableProtocol {

  late Protocol protocol;

  RunnableProtocolType get type => RunnableProtocolType.adhoc;

  AdhocProtocol(ProtocolType protocolType) {
    protocol = Protocol(protocolType);
  }

  @override
  bool update({required ProtocolState state,
    String? sessionId, bool persist = true}) {
    // State is not tracked for now
    return true;
  }

}