// Defines the list of existing protocols and common properties of each.
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum ProtocolType {
  variable_daytime,  // Daytime recording of variable length.
  sleep,  // Nighttime sleep recording.
  eoec,  // Eyes-Open, Eyes-Closed recording.
  eyes_movement, // Eyes movement recording
  unknown
}

enum ProtocolState {
  not_started,
  skipped,
  running,
  cancelled,
  completed,
  unknown
}

abstract class Protocol {

  ProtocolType get type;

  DateTime get startTime;

  Duration get minDuration;

  Duration get maxDuration;

  Duration get disconnectTimeoutDuration;

  String get description;

  String get intro;

  String get name;

  factory Protocol(ProtocolType type, DateTime startTime,
      {Duration? minDuration, Duration? maxDuration}) {
    BaseProtocol protocol;
    switch (type) {
      case ProtocolType.variable_daytime:
        protocol = VariableDaytimeProtocol();
        break;
      case ProtocolType.sleep:
        protocol = SleepProtocol();
        break;
      default:
        throw("Class for protocol type ${type} isn't defined");
    }
    protocol.setStartTime(startTime);

    if (minDuration != null)
      protocol.setMinDuration(minDuration);
    if (maxDuration != null)
      protocol.setMaxDuration(maxDuration);

    return protocol;
  }

}

abstract class BaseProtocol implements Protocol {
  final CustomLogPrinter _logger = CustomLogPrinter('BaseProtocol');

  DateTime? _startTime;
  Duration? _minDurationOverride;
  Duration? _maxDurationOverride;

  ProtocolState _protocolState = ProtocolState.not_started;

  @override
  ProtocolType get type => ProtocolType.unknown;

  @override
  String get name => describeEnum(type);

  @override
  DateTime get startTime => _startTime!;

  @override
  Duration get disconnectTimeoutDuration => Duration(minutes: 5);

  BaseProtocol();

  @override
  void setStartTime(DateTime startTime) {
    this._startTime = startTime;
  }

  @override
  void setMinDuration(Duration duration) {
    _minDurationOverride = duration;
  }

  @override
  void setMaxDuration(Duration duration) {
    _maxDurationOverride = duration;
  }


}

class VariableDaytimeProtocol extends BaseProtocol {

  @override
  ProtocolType get type => ProtocolType.variable_daytime;

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 10);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(hours: 24);

  @override
  String get description => 'Record at daytime';

  @override
  String get intro => 'Run a recording of a variable amount of time at daytime.'
      ' You can stop the recording at any time.';

}

class SleepProtocol extends BaseProtocol {

  @override
  ProtocolType get type => ProtocolType.sleep;

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(hours: 1);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(hours: 10);

  // TODO(alex): add sleep protocol description
  @override
  String get description => 'Sleep';

  // TODO(alex): add sleep protocol intro
  @override
  String get intro => 'Sleep protocol intro';

}

ProtocolType protocolTypeFromString(String typeStr) {
  return ProtocolType.values.firstWhere((element) => element.name == typeStr,
      orElse: () => ProtocolType.unknown);
}

ProtocolState protocolStateFromString(String protocolStr) {
  return ProtocolState.values.firstWhere((element) => element.name == protocolStr,
      orElse: () => ProtocolState.unknown);
}