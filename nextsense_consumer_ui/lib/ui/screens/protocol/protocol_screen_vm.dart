import 'dart:async';
import 'dart:math';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter_common/domain/device_internal_state_event.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/domain/event.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/consumer_ui_firestore_manager.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/device_state_viewmodel.dart';
import 'package:nextsense_consumer_ui/managers/event_types_manager.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';

enum ProtocolCancelReason {
  none, deviceDisconnectedTimeout, dataReceivedTimeout, deviceNotReadyToRecord, deviceNotConnected,
  storageFull, devicePoweredOff}

// Protocol part scheduled in time in the protocol. The schedule can be repeated many times until
// the protocol time is complete.
class ScheduledProtocolPart {
  ProtocolPart protocolPart;
  int relativeMilliseconds;

  ScheduledProtocolPart({required this.protocolPart, required this.relativeMilliseconds});

  factory ScheduledProtocolPart.clone(ScheduledProtocolPart part) {
    return ScheduledProtocolPart(protocolPart: part.protocolPart,
        relativeMilliseconds: part.relativeMilliseconds);
  }
}

List<ScheduledProtocolPart> deepCopy(List<ScheduledProtocolPart> source) {
  return source.map((e) => ScheduledProtocolPart.clone(e)).toList();
}

class ProtocolScreenViewModel extends DeviceStateViewModel {
  static const Duration _dataReceivedTimeout = Duration(seconds: 60);
  static const Duration _timerTickInterval = Duration(milliseconds: 50);

  final EventTypesManager _eventTypesManager = getIt<EventTypesManager>();
  final DeviceManager deviceManager = getIt<DeviceManager>();
  final SessionManager sessionManager = getIt<SessionManager>();
  final ConsumerUiFirestoreManager _firestoreManager = getIt<ConsumerUiFirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final Protocol protocol;
  final bool useCountDownTimer;
  List<ScheduledProtocolPart> _scheduledProtocolParts = [];
  List<ScheduledProtocolPart> _initialScheduledProtocolParts = [];
  final CountDownController countDownController = CountDownController();
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreenViewModel');

  int milliSecondsElapsed = 0;
  int _blockStartMilliSeconds = 0;
  int _blockEndMilliSeconds = 0;
  bool sessionIsActive = false;
  int disconnectTimeoutSecondsLeft = 10;
  bool minDurationPassed = false;
  bool maxDurationPassed = false;
  Timer? timer;
  Timer? disconnectTimeoutTimer;
  ProtocolCancelReason protocolCancelReason = ProtocolCancelReason.none;
  bool protocolCompletedHandlerExecuted = false;
  int currentRepetition = 0;
  bool dataReceived = false;

  bool _timerPaused = false;
  DateTime? _currentEventStart;
  DateTime? _lastEventEnd;
  String? _currentEventMarker;
  int _currentProtocolPart = 0;
  Duration _repetitionTime = const Duration(seconds: 0);
  Timer? _dataReceivedTimer;
  CancelListening? _currentSessionDataReceivedListener;
  Duration? _currentVariableDuration;

  // This indicates that the minimum duration of the protocol is passed and can mark is as
  // completed.
  bool get protocolCompleted => minDurationPassed == true;
  int get repetitions => (protocol.minDuration.inSeconds / _repetitionTime.inSeconds).round();
  int get protocolIndex =>
      currentRepetition * _scheduledProtocolParts.length + _currentProtocolPart;
  bool get isError => !protocolCompleted && protocolCancelReason != ProtocolCancelReason.none;
  int get currentProtocolPart => _currentProtocolPart;

  ProtocolScreenViewModel(this.protocol, {this.useCountDownTimer = true}) {
    for (ProtocolPart part in protocol.protocolBlock) {
      _scheduledProtocolParts.add(ScheduledProtocolPart(protocolPart: part,
          relativeMilliseconds: _repetitionTime.inMilliseconds));
      _repetitionTime += part.duration;
    }
    _initialScheduledProtocolParts = deepCopy(_scheduledProtocolParts);
    _blockEndMilliSeconds = _repetitionTime.inMilliseconds;
  }

  @override
  void init() async {
    super.init();
    sessionIsActive = true;
    if (deviceCanRecord) {
      if (sessionManager.getCurrentSession() == null) {
        bool started = await startSession();
        if (!started) {
          return;
        }
        _dataReceivedTimer = Timer(
          _dataReceivedTimeout, () {
            _logger.log(Level.WARNING,
                'Did not receive data before the timeout of $_dataReceivedTimeout');
            protocolCancelReason = ProtocolCancelReason.dataReceivedTimeout;
            stopSession();
            notifyListeners();
          },
        );
        _currentSessionDataReceivedListener = NextsenseBase.listenToCurrentSessionDataReceived(
                (msg) {
          _dataReceivedTimer?.cancel();
          dataReceived = true;
          startTimer();
          notifyListeners();
          _logger.log(Level.INFO, 'Started to receive data from the device.');
        });
      } else {
        // Already in progress, show the progress.
        Duration elapsedTime = DateTime.now().difference(
            sessionManager.getCurrentSession()?.getStartDateTime() != null ?
            sessionManager.getCurrentSession()!.getStartDateTime()! : DateTime.now());
        _logger.log(Level.INFO,
            'Session already in progress for ${elapsedTime.inMilliseconds} milliseconds');
        sessionIsActive = true;
        dataReceived = true;
        startTimer(elapsedTime: elapsedTime);
      }
    } else {
      sessionIsActive = false;
      protocolCancelReason = ProtocolCancelReason.deviceNotConnected;
      setError("Device not connected.");
    }
  }

  Future<bool> startSession() async {
    _logger.log(Level.INFO, "startSession");

    milliSecondsElapsed = 0;
    _blockStartMilliSeconds = 0;
    _blockEndMilliSeconds = _repetitionTime.inMilliseconds;
    sessionIsActive = true;
    minDurationPassed = false;
    maxDurationPassed = false;
    _currentProtocolPart = 0;
    currentRepetition = 0;
    protocolCancelReason = ProtocolCancelReason.none;
    sessionIsActive = await _startProtocol();
    notifyListeners();
    return sessionIsActive;
  }

  Future stopSession() async {
    _logger.log(Level.INFO, "stopSession");
    _dataReceivedTimer?.cancel();
    cancelTimer();
    sessionIsActive = false;
    _stopProtocol();
    _currentSessionDataReceivedListener?.call();
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

  List<ProtocolPart> getRemainingProtocolParts() {
    return protocol.protocolBlock.sublist((protocolIndex % protocol.protocolBlock.length).toInt());
  }

  void startTimer({Duration? elapsedTime}) {
    final int protocolMinTimeSeconds = protocol.minDuration.inSeconds;
    final int protocolMaxTimeSeconds = protocol.maxDuration.inSeconds;
    if (timer?.isActive ?? false) timer?.cancel();
    if (elapsedTime == null) {
      milliSecondsElapsed = 0;
      if (_scheduledProtocolParts.isNotEmpty &&
          _scheduledProtocolParts[_currentProtocolPart].protocolPart.marker != null) {
        startEvent(_scheduledProtocolParts[_currentProtocolPart].protocolPart.marker!,
            sequentialEvent: true);
      }
    } else {
      milliSecondsElapsed = elapsedTime.inMilliseconds;
    }
    onTimerStart();
    timer = Timer.periodic(
      _timerTickInterval,
          (_) {
        if (_timerPaused) return;

        milliSecondsElapsed += _timerTickInterval.inMilliseconds;
        if (milliSecondsElapsed >= protocolMinTimeSeconds * 1000) {
          minDurationPassed = true;
        }
        if (milliSecondsElapsed >= protocolMaxTimeSeconds * 1000) {
          _logger.log(Level.INFO,
              'Protocol finished. ${milliSecondsElapsed / 1000} out of $protocolMaxTimeSeconds');
          maxDurationPassed = true;
          timer?.cancel();
          onTimerFinished();
        }
        onTimerTick(milliSecondsElapsed);
        notifyListeners();
      },
    );
  }

  void onTimerTick(int millisecondsElapsed) {
    if (_scheduledProtocolParts.isEmpty) {
      // The code after this is needed only if there are parts in the protocol.
      return;
    }
    bool advanceProtocol = false;
    // _logger.log(Level.FINE, "Current milliseconds: $milliSecondsElapsed");
    if (millisecondsElapsed >= _blockEndMilliSeconds &&
        _currentProtocolPart == _scheduledProtocolParts.length - 1) {
      // Start of a repetition, reset the block index and finish the current step.
      _logger.log(Level.FINE, "Starting a new protocol repetition.");
      if (_currentProtocolPart != 0) {
        ++currentRepetition;
        if (_scheduledProtocolParts[_currentProtocolPart].protocolPart.marker != null) {
          endEvent(DateTime.now());
        }
        advanceProtocol = true;
      }
      _currentProtocolPart = 0;
      _logger.log(Level.FINE, "Advanced protocol to part 0.");
      // _repetitionTime = _initialRepetitionTime;
      _scheduledProtocolParts = deepCopy(_initialScheduledProtocolParts);
      _blockStartMilliSeconds = millisecondsElapsed;
      _blockEndMilliSeconds = _blockStartMilliSeconds + _repetitionTime.inMilliseconds;
      _logger.log(Level.FINE, "Block End milliseconds: $_blockEndMilliSeconds");
      onAdvanceProtocolBlock();
    }
    int blockMillisecondsElapsed = millisecondsElapsed - _blockStartMilliSeconds;
    // Check if can advance the index to the next part.
    if (_currentProtocolPart < _scheduledProtocolParts.length - 1) {
      if (blockMillisecondsElapsed >=
          _scheduledProtocolParts[_currentProtocolPart + 1].relativeMilliseconds) {
        advanceProtocol = true;
        if (_scheduledProtocolParts[_currentProtocolPart].protocolPart.marker != null) {
          endEvent(DateTime.now());
        }
        ++_currentProtocolPart;
        _logger.log(Level.FINE, "Advanced protocol to part $_currentProtocolPart.");
      }
    }
    if (advanceProtocol) {
      ProtocolPart currentProtocolPart = _scheduledProtocolParts[_currentProtocolPart].protocolPart;
      if (currentProtocolPart.marker != null) {
        startEvent(currentProtocolPart.marker!, sequentialEvent: true);
      }
      if (currentProtocolPart.durationVariation != null) {
        Duration durationVariation = Duration(milliseconds: Random().nextInt(
            currentProtocolPart.durationVariation!.inMilliseconds));
        _currentVariableDuration = durationVariation;
        // Adjust future parts times to account for the duration variation.
        _blockEndMilliSeconds += durationVariation.inMilliseconds;
        _logger.log(Level.FINE, "Block End milliseconds: $_blockEndMilliSeconds");
        for (int i = _currentProtocolPart + 1; i < _scheduledProtocolParts.length; ++i) {
          _scheduledProtocolParts[i].relativeMilliseconds += durationVariation.inMilliseconds;
        }
        _logger.log(Level.FINE, "Variable duration: $_currentVariableDuration");
      }
      onAdvanceProtocol();
    }
  }

  void onTimerStart() {}

  void onTimerFinished() {
    _logger.log(Level.INFO, "onTimerFinished");
    if (useCountDownTimer) {
      countDownController.pause();
    }
    stopSession();
  }

  // Called when the protocol progresses to a new part.
  void onAdvanceProtocol() {}

  // Called when the protocol finishes a protocol block and advance to the next one.
  void onAdvanceProtocolBlock() {}

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
    if (_currentEventStart == null) {
      _logger.log(Level.WARNING, "Could not save event, no event start time!");
      return false;
    }
    DateTime eventStart = _currentEventStart!;
    String? currentMarker = _currentEventMarker;
    String? sessionId = sessionManager.currentSessionId;
    if (sessionId == null) {
      _logger.log(Level.SEVERE, "Could not save event $currentMarker, no session id!");
      return false;
    }
    if (_eventTypesManager.getEventType(currentMarker!) != null) {
      FirebaseEntity firebaseEntity = await _firestoreManager.addAutoIdEntity(
          [Table.sessions, Table.events], [sessionId]);
      Event event = Event(firebaseEntity);
      event..setValue(EventKey.start_datetime, eventStart)..setValue(
          EventKey.end_datetime, endTime)..setValue(EventKey.marker, currentMarker)..setValue(
          EventKey.type, _eventTypesManager.getEventType(currentMarker)!.id);
      return await event.save();
    }
    return true;
  }

  Future<bool> recordSingleEvent(String markerName) async {
    DateTime eventTime = DateTime.now();
    String? sessionId = sessionManager.currentSessionId;
    if (sessionId == null) {
      _logger.log(Level.SEVERE,
          "Could not save event $markerName, no session id!");
      return false;
    }
    FirebaseEntity firebaseEntity = await _firestoreManager.addAutoIdEntity(
        [Table.sessions, Table.events], [sessionId]);
    Event event = Event(firebaseEntity);
    event..setValue(EventKey.start_datetime, eventTime)
      ..setValue(EventKey.end_datetime, eventTime)
      ..setValue(EventKey.marker, markerName);
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
    if (useCountDownTimer) {
      countDownController.pause();
    }
    _timerPaused = true;
    disconnectTimeoutTimer?.cancel();
    // TODO(alex): get disconnect timeout from firebase
    disconnectTimeoutSecondsLeft = protocol.disconnectTimeoutDuration.inSeconds;
    disconnectTimeoutTimer = Timer.periodic(
      const Duration(seconds: 1),
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
    if (useCountDownTimer) {
      countDownController.resume();
    }
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
      case DeviceInternalStateEventType.uSdFull:
        protocolCancelReason = ProtocolCancelReason.storageFull;
        _stopProtocol();
        break;
      case DeviceInternalStateEventType.batteryLow:
      case DeviceInternalStateEventType.poweringOff:
        protocolCancelReason = ProtocolCancelReason.devicePoweredOff;
        _stopProtocol();
        break;
      case DeviceInternalStateEventType.unknown:
        _logger.log(Level.WARNING, 'Unknown device internal state received.');
        break;
        // TODO: Handle this case.
      case DeviceInternalStateEventType.usbCableConnected:
      case DeviceInternalStateEventType.usbCableDisconnected:
        // Nothing to do.
        break;
    }
  }

  Future<bool> _startProtocol() async {
    if (deviceManager.getConnectedDevice() != null) {
      _logger.log(Level.INFO, 'Starting ${protocol.name} protocol.');
      bool started = await sessionManager.startSession(
          device: deviceManager.getConnectedDevice()!,
          protocolName: protocol.name);
      if (!started) {
        setError("Failed to start streaming. Please try again and contact support if you need "
            "additional help.");
        protocolCancelReason = ProtocolCancelReason.deviceNotReadyToRecord;
        return false;
      }
      _authManager.user!.setRunningSession(sessionManager.getCurrentSession()!.reference);
      _authManager.user!.save();
      return true;
    } else {
      _logger.log(
          Level.WARNING, 'Cannot start ${protocol.name} protocol, device not connected.');
    }
    protocolCancelReason = ProtocolCancelReason.deviceNotReadyToRecord;
    return false;
  }

  void _stopProtocol() async {
    _logger.log(Level.INFO, 'Stopping ${protocol.name} protocol.');
    _timerPaused = false;
    try {
      _logger.log(Level.INFO, 'Stopping session.');
      await sessionManager.stopSession(deviceManager.getConnectedDevice()!.macAddress);
    } catch (e) {
      _logger.log(Level.WARNING, "Failed to stop streaming: $e");
    }
  }
}
