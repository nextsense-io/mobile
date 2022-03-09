import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum ProtocolCancelReason {
  none,
  deviceDisconnectedTimeout
}

class ProtocolScreenViewModel extends ChangeNotifier {

  final StudyManager _studyManager = getIt<StudyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');

  Protocol protocol;

  late StreamSubscription _deviceStateSubscription;

  int secondsElapsed = 0;
  bool sessionIsActive = false;

  int disconnectTimeoutSecondsLeft = 10;

  // This indicates that minimum duration of protocol is passed
  // and we can mark protocol as completed
  bool get protocolCompleted => minDurationPassed == true;
  bool minDurationPassed = false;
  bool maxDurationPassed = false;
  DeviceState deviceState = DeviceState.READY;
  bool get deviceIsConnected => deviceState == DeviceState.READY;

  Timer? timer;
  Timer? disconnectTimeoutTimer;
  bool _timerPaused = false;
  ProtocolCancelReason protocolCancelReason = ProtocolCancelReason.none;

  ProtocolScreenViewModel(this.protocol);

  void init() {
    _deviceStateSubscription = _deviceManager.deviceStateStream.listen((DeviceState state) {
      print('[TODO] ProtocolScreenViewModel.init deviceState $state');
      deviceState = state;
      switch (deviceState){
        case DeviceState.DISCONNECTED:
          _onDeviceDisconnected();
          break;
        case DeviceState.READY:
          _onDeviceReconnected();
          break;
        default: break;
      }
      notifyListeners();
    });
  }

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

  void _onDeviceDisconnected() {
    print('[TODO] ProtocolScreenViewModel._onDeviceDisconnected');
    _timerPaused = true;
    disconnectTimeoutTimer?.cancel();
    disconnectTimeoutSecondsLeft = protocol.disconnectTimeoutDuration.inSeconds;
    disconnectTimeoutTimer = Timer.periodic(
      Duration(seconds: 1),
          (_){
        _logger.log(Level.INFO, "disconnectTimeoutTimer tick");
        disconnectTimeoutSecondsLeft-=1;
        if (disconnectTimeoutSecondsLeft <= 0) {
          disconnectTimeoutTimer?.cancel();
          _onDisconnectTimeout();
        }
        notifyListeners();
      },
    );
  }

  void _onDeviceReconnected() {
    _timerPaused = false;
    disconnectTimeoutTimer?.cancel();
  }

  @override
  void dispose() {
    _deviceStateSubscription.cancel();
    super.dispose();
  }

  void _onDisconnectTimeout() {
    _logger.log(Level.WARNING, '_onDisconnectTimeout');
    protocolCancelReason = ProtocolCancelReason.deviceDisconnectedTimeout;
    stopSession();
  }

}