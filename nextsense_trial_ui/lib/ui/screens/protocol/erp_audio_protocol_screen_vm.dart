import 'package:flutter/widgets.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

class ERPAudioProtocolScreenViewModel extends ProtocolScreenViewModel {

  static final String _normalSound = "assets/sounds/audiobeep2_988Hz_0p1s.wav";
  static final String _oddSound = "assets/sounds/audiobeep1_350Hz_0p1s.wav";

  final AudioManager _audioManager = getIt<AudioManager>();

  int _normalSoundCachedId = -1;
  int _oddSoundCachedId = -1;

  ERPAudioProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol, useCountDownTimer: false);

  @override
  void init() async {
    _normalSoundCachedId = await _audioManager.cacheAudioFile(_normalSound);
    _oddSoundCachedId = await _audioManager.cacheAudioFile(_oddSound);
    super.init();
  }

  @override
  void dispose() {
    _audioManager.stopPlayingLastAudio();
    _audioManager.clearCache();
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
    if (getScheduledProtocolParts()[currentProtocolPart].protocolPart.state ==
        ERPAudioState.NORMAL_SOUND.name) {
      _audioManager.playAudioFile(_normalSoundCachedId);
    } else if (getScheduledProtocolParts()[currentProtocolPart].protocolPart.state ==
        ERPAudioState.ODD_SOUND.name) {
      _audioManager.playAudioFile(_oddSoundCachedId);
    }
  }
}