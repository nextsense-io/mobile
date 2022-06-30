import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state_event.dart';
import 'package:nextsense_trial_ui/domain/event.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:nextsense_trial_ui/viewmodels/device_state_viewmodel.dart';

enum ProtocolCancelReason { none, deviceDisconnectedTimeout }

// Protocol part scheduled in time in the protocol. The schedule can be repeated
// many times until the protocol time is complete.
class ScheduledProtocolPart {
  ProtocolPart protocolPart;
  int relativeSeconds;

  ScheduledProtocolPart({required ProtocolPart protocolPart,
    required int relativeSeconds}) :
        this.protocolPart = protocolPart,
        this.relativeSeconds = relativeSeconds;
}

class ProtocolScreenViewModel extends DeviceStateViewModel {
  final StudyManager _studyManager = getIt<StudyManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final RunnableProtocol runnableProtocol;
  final List<ScheduledProtocolPart> _scheduledProtocolParts = [];
  final CountDownController countDownController = CountDownController();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');

  int secondsElapsed = 0;
  bool sessionIsActive = false;
  int disconnectTimeoutSecondsLeft = 10;
  // This indicates that the minimum duration of the protocol is passed and can mark is as
  // completed.
  bool get protocolCompleted => minDurationPassed == true;
  bool minDurationPassed = false;
  bool maxDurationPassed = false;
  Timer? timer;
  Timer? disconnectTimeoutTimer;
  bool _timerPaused = false;
  ProtocolCancelReason protocolCancelReason = ProtocolCancelReason.none;
  bool protocolCompletedHandlerExecuted = false;
  DateTime? _currentEventStart;
  DateTime? _lastEventEnd;
  String? _currentEventMarker;
  int _currentProtocolPart = 0;
  int _currentRepetition = 0;
  Duration _repetitionTime = Duration(seconds: 0);

  Study? get currentStudy => _studyManager.currentStudy;
  Protocol get protocol => runnableProtocol.protocol;
  int get repetitions => (protocol.minDuration.inSeconds / _repetitionTime.inSeconds).round();
  int get protocolIndex =>
      _currentRepetition * _scheduledProtocolParts.length + _currentProtocolPart;

  ProtocolScreenViewModel(this.runnableProtocol) {
    for (ProtocolPart part in runnableProtocol.protocol.protocolBlock) {
      _scheduledProtocolParts.add(ScheduledProtocolPart(protocolPart: part,
          relativeSeconds: _repetitionTime.inSeconds));
      _repetitionTime += part.duration;
    }
  }

  @override
  void init() {
    super.init();
    startSession();
  }

  void startSession() {
    _logger.log(Level.INFO, "startSession");

    secondsElapsed = 0;
    sessionIsActive = true;
    minDurationPassed = false;
    maxDurationPassed = false;
    _currentProtocolPart = 0;
    _currentRepetition = 0;
    protocolCancelReason = ProtocolCancelReason.none;
    startTimer();
    _startProtocol();
  }

  Future stopSession() async {
    _logger.log(Level.INFO, "stopSession");

    cancelTimer();

    sessionIsActive = false;

    _stopProtocol();

    notifyListeners();
  }

  ProtocolPart? getCurrentProtocolPart() {
    if (_scheduledProtocolParts.isNotEmpty) {
      return _scheduledProtocolParts[_currentProtocolPart].protocolPart;
    }
    return null;
  }

  ScheduledProtocolPart? getCurrentScheduledProtocolPart() {
    if (_scheduledProtocolParts.isNotEmpty) {
      return _scheduledProtocolParts[_currentProtocolPart];
    }
    return null;
  }

  List<ScheduledProtocolPart> getScheduledProtocolParts() {
    return _scheduledProtocolParts;
  }

  void startTimer() {
    final int protocolMinTimeSeconds = protocol.minDuration.inSeconds;
    final int protocolMaxTimeSeconds = protocol.maxDuration.inSeconds;
    if (timer?.isActive ?? false) timer?.cancel();
    secondsElapsed = 0;
    if (_scheduledProtocolParts.isNotEmpty &&
        _scheduledProtocolParts[_currentProtocolPart]
        .protocolPart.marker != null) {
      startEvent(_scheduledProtocolParts[_currentProtocolPart]
          .protocolPart.marker!, sequentialEvent: true);
    }
    onTimerStart();
    timer = Timer.periodic(
      Duration(seconds: 1),
      (_) {
        if (_timerPaused) return;

        secondsElapsed += 1;
        if (secondsElapsed >= protocolMinTimeSeconds) {
          minDurationPassed = true;
        }
        if (secondsElapsed >= protocolMaxTimeSeconds) {
          maxDurationPassed = true;
          timer?.cancel();
          onTimerFinished();
        }
        onTimerTick(secondsElapsed);
        notifyListeners();
      },
    );
  }

  void onTimerTick(int secondsElapsed) {
    if (_scheduledProtocolParts.isEmpty) {
      // The code after this is needed only if there are parts in the protocol.
      return;
    }
    bool advanceProtocol = false;
    int blockSecondsElapsed = secondsElapsed % _repetitionTime.inSeconds;
    if (blockSecondsElapsed == 0) {
      // Start of a repetition, reset the block index and finish the current step.
      if (_currentProtocolPart != 0) {
        ++_currentRepetition;
        if (_scheduledProtocolParts[_currentProtocolPart].protocolPart.marker != null) {
          endEvent(DateTime.now());
        }
        advanceProtocol = true;
      }
      _currentProtocolPart = 0;
    }
    // Check if can advance the index to the next part.
    if (_currentProtocolPart < _scheduledProtocolParts.length - 1) {
      if (blockSecondsElapsed >=
          _scheduledProtocolParts[_currentProtocolPart + 1].relativeSeconds) {
        if (_scheduledProtocolParts[_currentProtocolPart].protocolPart.marker != null) {
          endEvent(DateTime.now());
        }
        ++_currentProtocolPart;
        advanceProtocol = true;
      }
    }
    if (advanceProtocol) {
      String? currentMarker = _scheduledProtocolParts[_currentProtocolPart].protocolPart.marker;
      if (currentMarker != null) {
        startEvent(currentMarker, sequentialEvent: true);
      }
      onAdvanceProtocol();
    }
  }

  void onTimerStart() {}

  void onTimerFinished() {
    _logger.log(Level.INFO, "onTimerFinished");
    stopSession();
  }

  // Called when the protocol progresses to a new part.
  void onAdvanceProtocol() {}

  void cancelTimer() {
    timer?.cancel();
  }

  void startEvent(String marker, {bool? sequentialEvent}) {
    if (sequentialEvent != null && sequentialEvent && _lastEventEnd != null) {
      _currentEventStart = _lastEventEnd;
    } else {
      _currentEventStart = DateTime.now();
    }
    _currentEventMarker = marker;
  }

  Future<bool> endEvent(DateTime endTime) async {
    _lastEventEnd = endTime;
    DateTime eventStart = _currentEventStart!;
    String? currentMarker = _currentEventMarker;
    String? sessionId = runnableProtocol.lastSessionId;
    if (sessionId == null) {
      _logger.log(Level.SEVERE, "Could not save event $currentMarker, no session id!");
      return false;
    }
    String eventId = '${currentMarker}-${eventStart.string}';
    FirebaseEntity? firebaseEntity = await _firestoreManager.queryEntity(
        [Table.sessions, Table.events], [sessionId, eventId]);
    if (firebaseEntity == null) {
      return false;
    }
    Event event = Event(firebaseEntity);
    event..setValue(EventKey.start_time, eventStart.toIso8601String())
        ..setValue(EventKey.end_time, endTime.toIso8601String())
        ..setValue(EventKey.marker, currentMarker);
    return await event.save();
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
    countDownController.pause();
    _timerPaused = true;
    disconnectTimeoutTimer?.cancel();
    // TODO(alex): get disconnect timeout from firebase
    disconnectTimeoutSecondsLeft = protocol.disconnectTimeoutDuration.inSeconds;
    disconnectTimeoutTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) {
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
    countDownController.resume();
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
      bool started = await _sessionManager.startSession(
          _deviceManager.getConnectedDevice()!,
          _studyManager.currentStudyId!,
          protocol.name);
      if (!started) {
        setError("Failed to start streaming. Please try again and contact support if you need "
            "additional help.");
        return;
      }
      bool updated = await runnableProtocol.update(
          state: ProtocolState.running,
          sessionId: _sessionManager.currentSessionId);
      if (!updated) {
        setError("Failed to start streaming. Please try again and contact support if you need "
            "additional help.");
      }
    } else {
      _logger.log(
          Level.WARNING, 'Cannot start ${protocol.name} protocol, device not connected.');
    }
  }

  void _stopProtocol() async {
    _logger.log(Level.INFO, 'Stopping ${protocol.name} protocol.');
    _timerPaused = false;
    try {
      if (_deviceManager.deviceIsConnected) {
        await _sessionManager.stopSession(_deviceManager.getConnectedDevice()!.macAddress);
      }
    } catch (e) {
      _logger.log(Level.WARNING, "Failed to stop streaming");
    }
    runnableProtocol.update(
        state: protocolCompleted
            ? ProtocolState.completed
            : ProtocolState.cancelled);
  }

  // Executed when protocol is successfully completed i.e. minimum duration is
  // passed
  void onProtocolCompleted() {
    _logger.log(Level.INFO, 'Protocol ${protocol.name} completed');
    runnableProtocol.update(state: ProtocolState.completed);
  }
}
