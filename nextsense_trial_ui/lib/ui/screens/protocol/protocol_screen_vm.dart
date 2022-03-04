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

  int secondsLeft = 0;
  bool sessionIsActive = false;

  Timer? timer;
  Protocol protocol;

  ProtocolScreenViewModel(this.protocol);

  Study? getStudy() {
      return _studyManager.getCurrentStudy();
  }

  startSession() {
    _logger.log(Level.INFO, "startSession");

    sessionIsActive = true;
    startTimer();

    protocol.start();

    notifyListeners();
  }

  stopSession() {
    _logger.log(Level.INFO, "stopSession");

    cancelTimer();

    sessionIsActive = false;
    secondsLeft = 0;

    protocol.stop();

    notifyListeners();
  }

  void startTimer() {
    final seconds = 3;
    if (timer?.isActive ?? false) timer?.cancel();
    secondsLeft = seconds;
    notifyListeners();
    timer = Timer.periodic(
      Duration(seconds: 1),
          (_){
            _logger.log(Level.INFO, "tick");
            secondsLeft-=1;
            if (secondsLeft <= 0) {
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