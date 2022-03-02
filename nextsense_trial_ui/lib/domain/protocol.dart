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

enum ProtocolName {
  variable_daytime,  // Daytime recording of variable length.
  sleep,  // Nighttime sleep recording.
  eoec,  // Eyes-Open, Eyes-Closed recording.
  eyes_movement  // Eyes movement recording.
}

enum ProtocolState {
  not_started,
  running,
  cancelled,
  finished
}

abstract class Protocol {
  Duration getMinDuration();

  Duration getMaxDuration();

  String getName();

  String getDescription();

  String getIntro();

  Future start();

  Future stop();
}

abstract class BaseProtocol implements Protocol {
  final DeviceManager _deviceManager = GetIt.instance.get<DeviceManager>();
  final AuthManager _authManager = GetIt.instance.get<AuthManager>();
  final SessionManager _sessionManager = GetIt.instance.get<SessionManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SessionScreen');

  Duration? _runTime;
  DateTime? _startTime;
  ProtocolState _protocolState = ProtocolState.not_started;

  @override
  Future start() async {
    if (_deviceManager.getConnectedDevice() != null) {
      _logger.log(Level.INFO, 'Starting ${getName()} protocol.');
      await _sessionManager.startSession(
          _deviceManager.getConnectedDevice()!.macAddress,
          _authManager.getUserEntity()!.getValue(UserKey.study),
          getName());
      _startTime = _sessionManager.getCurrentSession()?.getValue(
          SessionKey.start_datetime);
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

class VariableDaytimeProtocol extends BaseProtocol implements Protocol {

  @override
  Duration getMinDuration() {
    return Duration(minutes: 10);
  }

  @override
  Duration getMaxDuration() {
    return Duration(hours: 24);
  }

  @override
  String getName() {
    return describeEnum(ProtocolName.variable_daytime);
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