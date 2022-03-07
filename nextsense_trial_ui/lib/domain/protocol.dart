// Defines the list of existing protocols and common properties of each.
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/session.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:intl/intl.dart';

enum ProtocolType {
  variable_daytime,  // Daytime recording of variable length.
  sleep,  // Nighttime sleep recording.
  eoec,  // Eyes-Open, Eyes-Closed recording.
  eyes_movement, // Eyes movement recording
  unknown
}

enum ProtocolState {
  not_started,
  running,
  cancelled,
  finished
}

abstract class ProtocolInterface {
  Duration getMinDuration();

  Duration getMaxDuration();

  String getDescription();

  String getIntro();

  Future start();

  Future stop();
}

abstract class Protocol implements ProtocolInterface {
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  final SessionManager _sessionManager = GetIt.instance.get<SessionManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SessionScreen');

  Duration? _runTime;
  DateTime? _startTime;
  ProtocolState _protocolState = ProtocolState.not_started;
  ProtocolType get type => ProtocolType.unknown;

  // Returns protocol start time in format 'HH:MM'
  String? get startTimeAsString => _startTime != null
      ? DateFormat('HH:mm').format(_startTime!) : null;

  static ProtocolType typeFromString(String typeStr) {
    return ProtocolType.values.firstWhere((element) => element.name == typeStr,
        orElse: () => ProtocolType.unknown);
  }

  Protocol();

  factory Protocol.create(ProtocolType type) {
    switch (type) {
      case ProtocolType.variable_daytime:
        return VariableDaytimeProtocol();
      case ProtocolType.sleep:
        return SleepProtocol();
      default:
        throw("Class for protocol type ${type} isn't defined");
    }
  }

  void setStartTime(DateTime startTime) {
    _startTime = startTime;
  }

  String getName() {
    return describeEnum(type);
  }

  @override
  Future start() async {
    if (_deviceManager.getConnectedDevice() != null) {
      _logger.log(Level.INFO, 'Starting ${getName()} protocol.');
      await _sessionManager.startSession(
          _deviceManager.getConnectedDevice()!.macAddress,
          _authManager.getUserEntity()!.getValue(UserKey.study),
          getName());
      // Comment for now, cause giving exception
      /*_startTime = _sessionManager.getCurrentSession()?.getValue(
          SessionKey.start_datetime);*/
      _protocolState = ProtocolState.running;
    }
  }

  @override
  Future stop() async {
    _logger.log(Level.INFO, 'Stopping ${getName()} protocol.');
    await _sessionManager.stopSession(
        _deviceManager.getConnectedDevice()!.macAddress);
    _protocolState = ProtocolState.finished;
  }

}

class VariableDaytimeProtocol extends Protocol {

  @override
  ProtocolType get type => ProtocolType.variable_daytime;

  @override
  Duration getMinDuration() {
    return Duration(minutes: 10);
  }

  @override
  Duration getMaxDuration() {
    return Duration(hours: 24);
  }

  @override
  String getDescription() {
    return 'Record at daytime';
  }

  @override
  String getIntro() {
    return 'Run a recording of a variable amount of time at daytime. You can '
        'stop the recording at any time.';
  }
}

class SleepProtocol extends Protocol {

  @override
  ProtocolType get type => ProtocolType.sleep;

  @override
  Duration getMinDuration() {
    return Duration(minutes: 10);
  }

  @override
  Duration getMaxDuration() {
    return Duration(hours: 24);
  }

  @override
  String getDescription() {
    // TODO(alex): add sleep protocol description
    return 'Sleep';
  }

  @override
  String getIntro() {
    // TODO(alex): add sleep protocol intro?
    return 'Sleep protocol intro';
  }
}