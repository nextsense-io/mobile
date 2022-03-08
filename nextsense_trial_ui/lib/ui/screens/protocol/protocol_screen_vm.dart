import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class ProtocolScreenViewModel extends ChangeNotifier {

  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');

  int secondsElapsed = 0;
  bool sessionIsActive = false;

  // This indicates that minimum duration of protocol is passed
  // and we can mark protocol as completed
  bool get protocolCompleted => minDurationPassed == true;
  bool minDurationPassed = false;
  bool maxDurationPassed = false;


  Timer? timer;
  Protocol protocol;

  ProtocolScreenViewModel(this.protocol);

  Study? getCurrentStudy() {
      return _studyManager.getCurrentStudy();
  }

  startSession() {
    _logger.log(Level.INFO, "startSession");

    secondsElapsed = 0;
    sessionIsActive = true;
    startTimer();

    protocol.start();

    notifyListeners();
  }

  stopSession() {
    _logger.log(Level.INFO, "stopSession");

    cancelTimer();

    sessionIsActive = false;
    minDurationPassed = false;
    maxDurationPassed = false;

    protocol.stop();

    notifyListeners();
  }

  void startTimer() {
    final protocolMinTimeSeconds = protocol.getMinDuration().inSeconds;
    final protocolMaxTimeSeconds = protocol.getMaxDuration().inSeconds;
    if (timer?.isActive ?? false) timer?.cancel();
    secondsElapsed = 0;
    notifyListeners();
    timer = Timer.periodic(
      Duration(seconds: 1),
          (_){
            _logger.log(Level.INFO, "tick");
            secondsElapsed+=1;
            if (secondsElapsed >= protocolMinTimeSeconds) {
              minDurationPassed = true;
            }
            if (secondsElapsed >= protocolMaxTimeSeconds) {
              maxDurationPassed = true;
              timer?.cancel();
              onTimerFinished();
            }
            notifyListeners();
      },
    );
  }

  void onTimerFinished() {
    _logger.log(Level.INFO, "onTimerFinished");
    stopSession();
  }

  void cancelTimer() {
    timer?.cancel();
  }

}