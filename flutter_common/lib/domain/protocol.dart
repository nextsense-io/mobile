// Defines the list of existing protocols and common properties of each.
import 'package:flutter/foundation.dart';

enum ProtocolState {
  not_started,
  skipped,
  running,
  cancelled,
  completed,
  unknown
}

abstract class Protocol {
  String get type;
  DateTime get startTime;
  Duration get minDuration;
  Duration get maxDuration;
  Duration get disconnectTimeoutDuration;
  String get description;
  String get intro;
  String get name;
  String get nameForUser;
  List<String> get postRecordingSurveys;
  List<ProtocolPart> get protocolBlock;
}

// Part of a protocol that works in discrete phases.
class ProtocolPart {
  String state;
  Duration duration;
  String? marker;
  Duration? durationVariation;

  ProtocolPart({
    required this.state, required this.duration, String? text, this.marker,
    this.durationVariation});
}

abstract class BaseProtocol implements Protocol {
  DateTime? _startTime;
  Duration? minDurationOverride;
  Duration? maxDurationOverride;

  @override
  String get type => "unknown";

  @override
  String get name => describeEnum(type);

  @override
  DateTime get startTime => _startTime!;

  @override
  Duration get disconnectTimeoutDuration => const Duration(minutes: 5);

  @override
  List<ProtocolPart> get protocolBlock => [];

  @override
  List<String> get postRecordingSurveys => [];

  BaseProtocol();

  void setStartTime(DateTime startTime) {
    _startTime = startTime;
  }

  void setMinDuration(Duration duration) {
    minDurationOverride = duration;
  }

  void setMaxDuration(Duration duration) {
    maxDurationOverride = duration;
  }
}

ProtocolState protocolStateFromString(String protocolStateStr) {
  return ProtocolState.values.firstWhere(
          (element) => element.name == protocolStateStr,
      orElse: () => ProtocolState.unknown);
}
