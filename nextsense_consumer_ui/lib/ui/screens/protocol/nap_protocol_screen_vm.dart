import 'package:flutter_common/domain/earbuds_config.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';

enum SleepCalculationState {
  notStarted,
  calculating,
  calculated
}

class NapProtocolScreenViewModel extends ProtocolScreenViewModel {
  NapProtocolScreenViewModel(super.protocol);

  final Duration singleSleepEpoch = const Duration(seconds: 30 * 21);

  SleepCalculationState get sleepCalculationState => _sleepCalculationState;
  Map<String, dynamic>? get sleepStagingResults => _sleepStagingResults;
  List<dynamic>? get sleepStagingLabels => _sleepStagingLabels;
  List<dynamic>? get sleepStagingConfidences => _sleepStagingConfidences;

  SleepCalculationState _sleepCalculationState = SleepCalculationState.notStarted;
  Map<String, dynamic>? _sleepStagingResults;
  List<dynamic>? _sleepStagingLabels;
  List<dynamic>? _sleepStagingConfidences;

  Future calculateSleepStagingResults() async {
    _sleepCalculationState = SleepCalculationState.calculating;
    notifyListeners();
    Device? device = deviceManager.getConnectedDevice();
    if (device == null) {
      return null;
    }
    String channelName = '1';
    switch (device.type) {
      case DeviceType.xenon:
        channelName = EarbudsConfigs.getConfig(EarbudsConfigNames.XENON_B_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      case DeviceType.kauai:
        channelName = EarbudsConfigs.getConfig(EarbudsConfigNames.KAUAI_CONFIG.name.toLowerCase())
            .bestSignalChannel.toString();
        break;
      default:
        break;
    }
    _sleepStagingResults = await NextsenseBase.runSleepStaging(macAddress: device.macAddress,
        localSessionId: sessionManager.currentLocalSession!, channelName: channelName,
        duration: singleSleepEpoch);
    _sleepStagingLabels = _sleepStagingResults!["0"] as List<dynamic>;
    _sleepStagingConfidences = _sleepStagingResults!["1"] as List<dynamic>;
    _sleepCalculationState = SleepCalculationState.calculated;
    notifyListeners();
  }

  @override
  Future stopSession() async {
    await super.stopSession();
    await calculateSleepStagingResults();
  }
}