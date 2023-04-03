import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:wakelock/wakelock.dart';

class BioCalibrationProtocolScreenViewModel extends ProtocolScreenViewModel {
  static const Map<BioCalibrationState, String> _protocolPartsText = {
    BioCalibrationState.NOT_RUNNING: "",
    BioCalibrationState.REST: "Rest",
    BioCalibrationState.BLINK: "10x Blink",
    BioCalibrationState.MOVE_HORIZONTAL: "10x Eyes Right-Left",
    BioCalibrationState.MOVE_VERTICAL: "10x Up-Down",
    BioCalibrationState.JAW_CLENCH: "Clench your jaws"
  };
  static const Map<BioCalibrationState, ImageProvider> _protocolPartsImage = {
    BioCalibrationState.REST: Svg('assets/images/plant.svg'),
    BioCalibrationState.BLACK_SCREEN: Svg('assets/images/plant.svg'),
    BioCalibrationState.BLINK: Svg('assets/images/blinking.svg'),
    BioCalibrationState.MOVE_HORIZONTAL: Svg('assets/images/left_right.svg'),
    BioCalibrationState.MOVE_VERTICAL: Svg('assets/images/up_down.svg'),
    BioCalibrationState.JAW_CLENCH: Svg('assets/images/plant.svg'),
  };

  final protocolPartChangeStream = StreamController<int>.broadcast();

  BioCalibrationProtocolScreenViewModel(RunnableProtocol runnableProtocol) :
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

  String getTextForProtocolPart(String bioCalibrationStateString) {
    BioCalibrationState bioCalibrationState = BioCalibrationState.values.firstWhere(
            (e) => describeEnum(e) == bioCalibrationStateString,
        orElse: () => BioCalibrationState.UNKNOWN);
    if (bioCalibrationState == BioCalibrationState.UNKNOWN) {
      return "";
    }
    return _protocolPartsText[bioCalibrationState]!;
  }

  ImageProvider getImageForProtocolPart(String bioCalibrationStateString) {
    BioCalibrationState bioCalibrationState = BioCalibrationState.values.firstWhere(
            (e) => describeEnum(e) == bioCalibrationStateString,
        orElse: () => BioCalibrationState.UNKNOWN);
    if (bioCalibrationState == BioCalibrationState.UNKNOWN) {
      throw('Unknown Bio Calibration state.');
    }
    return _protocolPartsImage[bioCalibrationState]!;
  }
}