import 'package:nextsense_consumer_ui/domain/protocol.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/nap_protocol_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen.dart';

class ProtocolScreenMapping {
  static const Map<ProtocolType, String> _protocolScreenByType = {
    ProtocolType.nap: NapProtocolScreen.id,
    ProtocolType.sleep: NapProtocolScreen.id,
    ProtocolType.variable_daytime: ProtocolScreen.id,
  };

  static getProtocolScreenId(ProtocolType protocolType) {
    return _protocolScreenByType[protocolType];
  }
}