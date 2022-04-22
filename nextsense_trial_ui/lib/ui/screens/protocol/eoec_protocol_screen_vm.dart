import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/managers/audio_manager.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

enum EOECState {
  EO,  // Eyes Open
  EC  // Eyes Closed
}

class EOECProtocolScreenViewModel extends ProtocolScreenViewModel {

  static final ProtocolPart _eyesOpen = ProtocolPart(
      state: EOECState.EO.name,
      duration: Duration(seconds: 30),
      text: "Keep your eyes open",
      marker: EOECState.EO.name);
  static final ProtocolPart _eyesClosed = ProtocolPart(
      state: EOECState.EO.name,
      duration: Duration(seconds: 30),
      text: "Keep your eyes closed",
      marker: EOECState.EC.name);
  static final List<ProtocolPart> _block = [_eyesOpen, _eyesClosed];
  static final String _eoec_transition_sound = "sounds/eoec_transition.wav";

  final AudioManager _audioManager = getIt<AudioManager>();
  final List<ScheduledProtocolPart> _scheduledProtocolParts = [];

  int _currentProtocolPart = 0;
  Duration _repetitionTime = Duration(seconds: 0);

  EOECProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol) {
    _audioManager.cacheAudioFile(_eoec_transition_sound);
    for (ProtocolPart part in _block) {
      _scheduledProtocolParts.add(ScheduledProtocolPart(protocolPart: part,
          relativeSeconds: _repetitionTime.inSeconds));
      _repetitionTime += part.duration;
    }
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
  void onTimerTick(int secondsElapsed) {
    bool advanceProtocol = false;
    int blockSecondsElapsed = secondsElapsed % _repetitionTime.inSeconds;
    if (blockSecondsElapsed == 0) {
      // Start of a repetition, reset the block index and finish the current
      // step.
      if (_currentProtocolPart != 0) {
        // if (_scheduledProtocolParts[_currentProtocolPart]
        //     .protocolPart.marker != null) {
        //   _protocolStatus.endEvent();
        // }
        advanceProtocol = true;
      }
      _currentProtocolPart = 0;
    }
    // Check if can advance the index to the next part.
    if (_currentProtocolPart < _scheduledProtocolParts.length - 1) {
      if (blockSecondsElapsed >=
          _scheduledProtocolParts[_currentProtocolPart + 1].relativeSeconds) {
        // if (_scheduledProtocolParts[_currentProtocolPart]
        //     .protocolPart.marker != null) {
        //   _protocolStatus.endEvent();
        // }
        ++_currentProtocolPart;
        advanceProtocol = true;
      }
    }
    if (advanceProtocol) {
      _audioManager.playAudioFile(_eoec_transition_sound);
      // String currentMarker = _scheduledProtocolParts[_currentProtocolPart]
      //     .protocolPart.marker;
      // if (currentMarker != null) {
      //   _protocolStatus.startEvent(currentMarker);
      // }
    }
  }

  ProtocolPart getCurrentProtocolPart() {
    return _scheduledProtocolParts[_currentProtocolPart].protocolPart;
  }
}