import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

enum ProtocolCancelReason {
  none,
  deviceDisconnectedTimeout
}

class ProtocolScreenViewModel extends DeviceStateViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();

  final RunnableProtocol runnableProtocol;
  Protocol get protocol => runnableProtocol.protocol;

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


  bool protocolCompletedHandlerExecuted = false;

  ProtocolScreenViewModel(this.runnableProtocol);

  Study? get currentStudy => _studyManager.currentStudy;

  void startSession() {
    _logger.log(Level.INFO, "startSession");

    secondsElapsed = 0;
    sessionIsActive = true;
    minDurationPassed = false;
    maxDurationPassed = false;
    protocolCancelReason = ProtocolCancelReason.none;
    startTimer();
    _startProtocol();

    notifyListeners();
  }

  void stopSession() {
    _logger.log(Level.INFO, "stopSession");

    cancelTimer();

    sessionIsActive = false;

    _stopProtocol();

    notifyListeners();
  }

  void startTimer() {
    final int protocolMinTimeSeconds = protocol.minDuration.inSeconds;
    final int protocolMaxTimeSeconds = protocol.maxDuration.inSeconds;
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
    _pauseProtocol();
  }

  @override
  void onDeviceReconnected() {
    _restartProtocol();
  }

  void _onDisconnectTimeout() {
    _logger.log(Level.WARNING, '_onDisconnectTimeout');
    protocolCancelReason = ProtocolCancelReason.deviceDisconnectedTimeout;
    stopSession();
  }

  void _pauseProtocol() {
    _timerPaused = true;
    disconnectTimeoutTimer?.cancel();
    // TODO(alex): get disconnect timeout from firebase
    disconnectTimeoutSecondsLeft =
        protocol.disconnectTimeoutDuration.inSeconds;
    disconnectTimeoutTimer = Timer.periodic(
      Duration(seconds: 1), (_){
      disconnectTimeoutSecondsLeft -= 1;
      if (disconnectTimeoutSecondsLeft <= 0) {
        disconnectTimeoutTimer?.cancel();
        _onDisconnectTimeout();
      }
      notifyListeners();
    },
    );
  }

  void _restartProtocol() {
    _timerPaused = false;
    disconnectTimeoutTimer?.cancel();
  }

  @override
  void onDeviceInternalStateChanged(DeviceInternalStateEvent event) {
    _logger.log(Level.INFO, 'onDeviceInternalStateChanged ${event.type.name}');
    switch (event.type) {
      case DeviceInternalStateEventType.hdmiCableDisconnected:
        _pauseProtocol();
        break;
      case DeviceInternalStateEventType.hdmiCableConnected:
        if (_timerPaused) {
          _restartProtocol();
        }
        break;
      case DeviceInternalStateEventType.uSdDisconnected:
        _pauseProtocol();
        break;
      case DeviceInternalStateEventType.uSdConnected:
        if (_timerPaused) {
          _restartProtocol();
        }
        break;
      case DeviceInternalStateEventType.unknown:
        _logger.log(Level.WARNING, 'Unknown device internal state received.');
        break;
    }
  }

  void _startProtocol() async {
    if (_deviceManager.getConnectedDevice() != null) {
      _logger.log(Level.INFO, 'Starting ${protocol.name} protocol.');
      await _sessionManager.startSession(
          _deviceManager.getConnectedDevice()!.macAddress,
          _studyManager.currentStudyId!,
          protocol.name);
      runnableProtocol.update(
          state: ProtocolState.running,
          sessionId: _sessionManager.currentSessionId
      );
    } else {
      _logger.log(Level.WARNING, 'Cannot start ${protocol.name} protocol, device '
          'not connected.');
    }
  }

  void _stopProtocol() async {
    _logger.log(Level.INFO, 'Stopping ${protocol.name} protocol.');
    await _sessionManager
        .stopSession(_deviceManager.getConnectedDevice()!.macAddress);
    runnableProtocol.update(
        state: protocolCompleted
            ? ProtocolState.completed
            : ProtocolState.cancelled);
  }

  // Executed when protocol is successfully completed i.e. minimum duration is
  // passed
  void onProtocolCompleted() {
    _logger.log(Level.INFO, 'Protocol ${protocol.name} completed');
    runnableProtocol.update(
        state: ProtocolState.completed
    );
  }

}