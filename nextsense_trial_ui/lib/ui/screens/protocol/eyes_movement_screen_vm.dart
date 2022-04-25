import 'package:flutter/foundation.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

class EyesMovementProtocolScreenViewModel extends ProtocolScreenViewModel {
  static const Map<EyesMovementState, String> _protocolPartsText = {
    EyesMovementState.NOT_RUNNING: "",
    EyesMovementState.REST: "REST",
    EyesMovementState.BLACK_SCREEN: "",
    EyesMovementState.BLINK: "10 x BLINK",
    EyesMovementState.MOVE_RIGHT_LEFT: "5 x RIGHT-LEFT",
    EyesMovementState.MOVE_LEFT_RIGHT: "5 x LEFT-RIGHT",
    EyesMovementState.MOVE_UP_DOWN: "5 x UP-DOWN",
    EyesMovementState.MOVE_DOWN_UP: "5 x DOWN-UP"
  };

  final List<ScheduledProtocolPart> _scheduledProtocolParts = [];

  int _currentProtocolPart = 0;
  Duration _repetitionTime = Duration(seconds: 0);

  EyesMovementProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol) {
    for (ProtocolPart part in runnableProtocol.protocol.protocolBlock) {
      _scheduledProtocolParts.add(ScheduledProtocolPart(protocolPart: part,
          relativeSeconds: _repetitionTime.inSeconds));
      _repetitionTime += part.duration;
    }
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

  String getTextForProtocolPart(String eyesMovementStateString) {
    EyesMovementState eyesMovementState = EyesMovementState.values.firstWhere(
            (e) => describeEnum(e) == eyesMovementStateString,
        orElse: () => EyesMovementState.UNKNOWN);
    if (eyesMovementState == EyesMovementState.UNKNOWN) {
      return "";
    }
    return _protocolPartsText[eyesMovementState]!;
  }
}