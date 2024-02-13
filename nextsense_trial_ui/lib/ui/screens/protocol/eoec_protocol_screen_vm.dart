import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class EOECProtocolScreenViewModel extends ProtocolScreenViewModel {

  static const String _eoecTransitionSound = "packages/nextsense_trial_ui/assets/sounds/eoec_transition.wav";
  static const Map<EOECState, String> _protocolPartsText = {
    EOECState.EO: 'Eyes Open',
    EOECState.EC: 'Eyes Closed'
  };
  static const Map<EOECState, ImageProvider> _protocolPartsImage = {
    EOECState.EO: Svg('packages/nextsense_trial_ui/assets/images/eye_open.svg'),
    EOECState.EC: Svg('packages/nextsense_trial_ui/assets/images/eye_closed.svg')
  };

  final AudioManager _audioManager = getIt<AudioManager>();
  int _eoecTransitionSoundCachedId = -1;

  EOECProtocolScreenViewModel(RunnableProtocol runnableProtocol) : super(runnableProtocol);

  @override
  void init() async {
    super.init();
    _eoecTransitionSoundCachedId = await _audioManager.cacheAudioFile(_eoecTransitionSound);
  }

  @override
  void dispose() {
    _audioManager.stopPlayingLastAudio();
    _audioManager.clearCache();
    super.dispose();
  }

  @override
  void onTimerStart() {
    WakelockPlus.enable();
    super.onTimerStart();
  }

  @override
  void onTimerFinished() {
    super.onTimerFinished();
    WakelockPlus.disable();
  }

  @override
  void onAdvanceProtocol() {
    _audioManager.playAudioFile(_eoecTransitionSoundCachedId);
  }

  String getTextForProtocolPart(String eoecStateString) {
    EOECState eoecState = EOECState.values.firstWhere(
        (e) => describeEnum(e) == eoecStateString,
        orElse: () => EOECState.UNKNOWN);
    if (eoecState == EOECState.UNKNOWN) {
      return "";
    }
    return _protocolPartsText[eoecState]!;
  }

  ImageProvider getImageForProtocolPart(String eoecStateString) {
    EOECState eoecState = EOECState.values.firstWhere(
            (e) => describeEnum(e) == eoecStateString,
        orElse: () => EOECState.UNKNOWN);
    if (eoecState == EOECState.UNKNOWN) {
      throw('Unknown EOEC state.');
    }
    return _protocolPartsImage[eoecState]!;
  }
}