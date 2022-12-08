import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

class EyesMovementProtocolScreenViewModel extends ProtocolScreenViewModel {
  static const Map<EyesMovementState, String> _protocolPartsText = {
    EyesMovementState.NOT_RUNNING: "",
    EyesMovementState.REST: "Rest",
    EyesMovementState.BLACK_SCREEN: "Rest",
    EyesMovementState.BLINK: "10x Blink",
    EyesMovementState.MOVE_RIGHT_LEFT: "5x Eyes Right-Left",
    EyesMovementState.MOVE_LEFT_RIGHT: "5x Left-Right",
    EyesMovementState.MOVE_UP_DOWN: "5x Up-Down",
    EyesMovementState.MOVE_DOWN_UP: "5x Down-Up"
  };
  static const Map<EyesMovementState, ImageProvider> _protocolPartsImage = {
    EyesMovementState.REST: Svg('assets/images/plant.svg'),
    EyesMovementState.BLACK_SCREEN: Svg('assets/images/plant.svg'),
    EyesMovementState.BLINK: Svg('assets/images/blinking.svg'),
    EyesMovementState.MOVE_RIGHT_LEFT: Svg('assets/images/left_right.svg'),
    EyesMovementState.MOVE_LEFT_RIGHT: Svg('assets/images/left_right.svg'),
    EyesMovementState.MOVE_UP_DOWN: Svg('assets/images/up_down.svg'),
    EyesMovementState.MOVE_DOWN_UP: Svg('assets/images/up_down.svg'),
  };

  final protocolPartChangeStream = StreamController<int>.broadcast();

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

  @override
  onAdvanceProtocol() {
    protocolPartChangeStream.sink.add(
        (protocolIndex % runnableProtocol.protocol.protocolBlock.length).round());
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

  ImageProvider getImageForProtocolPart(String eyesMovementStateString) {
    EyesMovementState eyesMovementState = EyesMovementState.values.firstWhere(
            (e) => describeEnum(e) == eyesMovementStateString,
        orElse: () => EyesMovementState.UNKNOWN);
    if (eyesMovementState == EyesMovementState.UNKNOWN) {
      throw('Unknown Eyes Movement state.');
    }
    return _protocolPartsImage[eyesMovementState]!;
  }
}