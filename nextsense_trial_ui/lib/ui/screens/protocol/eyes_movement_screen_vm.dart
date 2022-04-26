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

  EyesMovementProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
        super(runnableProtocol);

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