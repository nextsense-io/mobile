import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eoec_protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eyes_movement_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';

class ProtocolScreenMapping {
  static const Map<ProtocolType, String> _protocolScreenByType = {
    ProtocolType.eoec: EOECProtocolScreen.id,
    ProtocolType.eyes_movement: EyesMovementProtocolScreen.id,
    ProtocolType.nap: ProtocolScreen.id,
    ProtocolType.sleep: ProtocolScreen.id,
    ProtocolType.variable_daytime: ProtocolScreen.id,
  };

  static getProtocolScreenId(ProtocolType protocolType) {
    return _protocolScreenByType[protocolType];
  }
}