import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ABRProtocolScreenViewModel extends ProtocolScreenViewModel {
  ABRProtocolScreenViewModel(RunnableProtocol runnableProtocol) : super(runnableProtocol);

  static const String _abrSound =
      "packages/nextsense_trial_ui/assets/sounds/abr_stimulus_stereo_30sec.wav";

  final AudioManager _audioManager = getIt<AudioManager>();
  int _abrSoundCachedId = -1;

  @override
  void init() async {
    super.init();
    _abrSoundCachedId = await _audioManager.cacheAudioFile(_abrSound);
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
    _audioManager.playAudioFile(_abrSoundCachedId, repeat: 100);
  }

  @override
  void onTimerFinished() {
    super.onTimerFinished();
    _audioManager.stopPlayingLastAudio();
    WakelockPlus.disable();
  }

  @override
  void onAdvanceProtocol() {
    super.onAdvanceProtocol();
  }
}