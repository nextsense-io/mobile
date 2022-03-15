import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/notifications_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_vm.dart';

enum ProtocolCancelReason {
  none,
  deviceDisconnectedTimeout
}

class ProtocolScreenViewModel extends DeviceStateViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');

  Protocol protocol;

  int secondsElapsed = 0;
  bool sessionIsActive = false;

  int disconnectTimeoutSecondsLeft = 10;

  // This indicates that minimum duration of protocol is passed
  // and we can mark protocol as completed
  bool get protocolCompleted => minDurationPassed == true;
  bool minDurationPassed = false;
  bool maxDurationPassed = false;

  Timer? timer;
  Timer? disconnectTimeoutTimer;
  bool _timerPaused = false;
  ProtocolCancelReason protocolCancelReason = ProtocolCancelReason.none;

  ProtocolScreenViewModel(this.protocol);

  Study? getCurrentStudy() {
    return _studyManager.getCurrentStudy();
  }

  void startSession() {
    _logger.log(Level.INFO, "startSession");

    secondsElapsed = 0;
    sessionIsActive = true;
    minDurationPassed = false;
    maxDurationPassed = false;
    protocolCancelReason = ProtocolCancelReason.none;
    startTimer();

    protocol.start();

    notifyListeners();
  }

  void stopSession() {
    _logger.log(Level.INFO, "stopSession");

    cancelTimer();

    sessionIsActive = false;

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

        if (_timerPaused) return;

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


  @override
  void onDeviceDisconnected() {
    _timerPaused = true;
    disconnectTimeoutTimer?.cancel();
    // TODO(alex): get disconnect timeout from firebase
    disconnectTimeoutSecondsLeft = protocol.disconnectTimeoutDuration.inSeconds;
    disconnectTimeoutTimer = Timer.periodic(
      Duration(seconds: 1),
          (_){
        disconnectTimeoutSecondsLeft-=1;
        if (disconnectTimeoutSecondsLeft <= 0) {
          disconnectTimeoutTimer?.cancel();
          _onDisconnectTimeout();
        }
        notifyListeners();
      },
    );
  }

  @override
  void onDeviceReconnected() {
    _timerPaused = false;
    disconnectTimeoutTimer?.cancel();
  }

  void _onDisconnectTimeout() {
    _logger.log(Level.WARNING, '_onDisconnectTimeout');
    protocolCancelReason = ProtocolCancelReason.deviceDisconnectedTimeout;
    stopSession();
  }

  @override
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event) {
    _logger.log(Level.INFO, 'onDeviceInternalStateChanged $event');
  }

}