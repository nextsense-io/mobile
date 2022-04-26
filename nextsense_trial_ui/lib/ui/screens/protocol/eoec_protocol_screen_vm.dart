import 'package:flutter/foundation.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

class EOECProtocolScreenViewModel extends ProtocolScreenViewModel {

  static final String _eoec_transition_sound = "sounds/eoec_transition.wav";
  static const Map<EOECState, String> _protocolPartsText = {
    EOECState.EO: 'Keep your eyes open',
    EOECState.EC: 'Keep your eyes closed'
  };

  final AudioManager _audioManager = getIt<AudioManager>();

  EOECProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol) {
    _audioManager.cacheAudioFile(_eoec_transition_sound);
  }

  @override
  void dispose() {
    _audioManager.stopPlayingAudio();
    super.dispose();
  }

  @override
  void onTimerStart() {
    Wakelock.enable();
    super.onTimerStart();
  }

  @override
  void onTimerFinished() {
    super.onTimerFinished();
    Wakelock.disable();
  }

  @override
  void onAdvanceProtocol() {
    _audioManager.playAudioFile(_eoec_transition_sound);
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
}