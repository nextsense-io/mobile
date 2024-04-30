import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:nextsense_consumer_ui/domain/protocol.dart';

class StartAdhocProtocolDialogViewModel extends ViewModel {

  List<Protocol> getProtocols() {
    return [VariableDaytimeProtocol(), SleepProtocol(), NapProtocol(), MentalStateAudioProtocol()];
  }
}
