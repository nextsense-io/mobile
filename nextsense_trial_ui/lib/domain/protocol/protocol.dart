// Defines the list of existing protocols and common properties of each.
import 'package:flutter/foundation.dart';

enum ProtocolType {
  variable_daytime,  // Daytime recording of variable length.
  sleep,  // Nighttime sleep recording.
  eoec,  // Eyes-Open, Eyes-Closed recording.
  eyes_movement, // Eyes movement recording
  nap,  // Nap recording.
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
  String get nameForUser;
  List<String> get postRecordingSurveys;
  List<ProtocolPart> get protocolBlock;

  factory Protocol(ProtocolType type,
      {DateTime? startTime, Duration? minDuration, Duration? maxDuration}) {
    BaseProtocol protocol;
    switch (type) {
      case ProtocolType.variable_daytime:
        protocol = VariableDaytimeProtocol();
        break;
      case ProtocolType.sleep:
        protocol = SleepProtocol();
        break;
      case ProtocolType.nap:
        protocol = NapProtocol();
        break;
      case ProtocolType.eoec:
        protocol = EyesOpenEyesClosedProtocol();
        break;
      case ProtocolType.eyes_movement:
        protocol = EyesMovementProtocol();
        break;
      default:
        throw("Class for protocol type ${type} isn't defined");
    }
    if (startTime != null) {
      protocol.setStartTime(startTime);
    }
    if (minDuration != null) {
      protocol.setMinDuration(minDuration);
    }
    if (maxDuration != null) {
      protocol.setMaxDuration(maxDuration);
    }

    return protocol;
  }
}

// Part of a protocol that works in discrete phases.
class ProtocolPart {
  String state;
  Duration duration;
  String? marker;

  ProtocolPart({
    required String state, required Duration duration, String? text, String? marker}) :
        this.state = state,
        this.duration = duration,
        this.marker = marker;
}

abstract class BaseProtocol implements Protocol {
  DateTime? _startTime;
  Duration? _minDurationOverride;
  Duration? _maxDurationOverride;

  @override
  ProtocolType get type => ProtocolType.unknown;

  @override
  String get name => describeEnum(type);

  @override
  DateTime get startTime => _startTime!;

  @override
  Duration get disconnectTimeoutDuration => Duration(minutes: 5);

  @override
  List<ProtocolPart> get protocolBlock => [];

  @override
  List<String> get postRecordingSurveys => [];

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
  String get nameForUser => "Daytime";

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 0);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(hours: 24);

  @override
  String get description => 'Record at daytime';

  @override
  String get intro => 'Records for a variable amount of time at daytime.'
      ' You can stop the recording at any time.';
}

class SleepProtocol extends BaseProtocol {

  @override
  ProtocolType get type => ProtocolType.sleep;

  @override
  String get nameForUser => 'Sleep';

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 0);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(hours: 12);

  @override
  String get description => 'Sleep';

  @override
  String get intro => 'Lay down in bed to get ready for your night then press the start button.';
}

class NapProtocol extends BaseProtocol {

  @override
  ProtocolType get type => ProtocolType.nap;

  @override
  String get nameForUser => 'Nap';

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 0);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(hours: 4);

  @override
  String get description => 'Nap';

  @override
  String get intro =>
      'Get ready in a comfortable position for your nap then press the start button.';

  @override
  List<String> get postRecordingSurveys => ['nap'];
}

enum EOECState {
  UNKNOWN,
  EO,  // Eyes Open
  EC  // Eyes Closed
}

class EyesOpenEyesClosedProtocol extends BaseProtocol {

  static final ProtocolPart _eyesOpen = ProtocolPart(
      state: EOECState.EO.name,
      duration: Duration(seconds: 60),
      marker: EOECState.EO.name);
  static final ProtocolPart _eyesClosed = ProtocolPart(
      state: EOECState.EC.name,
      duration: Duration(seconds: 60),
      marker: EOECState.EC.name);
  static final List<ProtocolPart> _protocolBlock = [_eyesOpen, _eyesClosed];

  @override
  ProtocolType get type => ProtocolType.eoec;

  @override
  String get nameForUser => "Eyes Open, Eyes Closed";

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 4);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(minutes: 4);

  @override
  Duration get disconnectTimeoutDuration => Duration(seconds: 20);

  @override
  String get description => 'Eyes Open, Eyes Closed';

  @override
  String get intro => 'IMPORTANT: Make sure the sound is perceivable and adjust the '
      'volume if needed.\n\n'
      'You will be asked to do the following:\n'
      '-1 min: Eyes open\n'
      '-1 min: Eyes closed\n'
      '-1 min: Eyes open\n'
      '-1 min: Eyes closed\n\n'
      ' • Sounds will be played to indicate transitions from EO to EC and EC to EO.\n'
      ' • Sit down comfortably at your desk.\n'
      ' • Place the phone at your desk with the sound output facing.';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;
}

enum EyesMovementState {
  UNKNOWN,
  NOT_RUNNING,
  REST,  // Rest period.
  BLACK_SCREEN,  // Show black screen between activities.
  BLINK,  // Blink eyes.
  MOVE_RIGHT_LEFT,  // Moves eyes back and forth horizontally.
  MOVE_LEFT_RIGHT,  // Moves eyes back and forth horizontally.
  MOVE_UP_DOWN,  // Moves eyes back and forth vertically.
  MOVE_DOWN_UP,  // Moves eyes back and forth vertically.
}

class EyesMovementProtocol extends BaseProtocol {

  static final ProtocolPart _rest = ProtocolPart(
      state: EyesMovementState.REST.name,
      duration: Duration(seconds: 15),
      marker: "REST");
  static final ProtocolPart _blackScreen = ProtocolPart(
      state: EyesMovementState.BLACK_SCREEN.name,
      duration: Duration(seconds: 5),
      marker: "REST");
  static final ProtocolPart _blink = ProtocolPart(
      state: EyesMovementState.BLINK.name,
      duration: Duration(seconds: 10),
      marker: "BLINKS");
  static final ProtocolPart _rightLeft = ProtocolPart(
      state: EyesMovementState.MOVE_RIGHT_LEFT.name,
      duration: Duration(seconds: 10),
      marker: "HEOG");
  static final ProtocolPart _leftRight = ProtocolPart(
      state: EyesMovementState.MOVE_LEFT_RIGHT.name,
      duration: Duration(seconds: 10),
      marker: "HEOG");
  static final ProtocolPart _upDown = ProtocolPart(
      state: EyesMovementState.MOVE_UP_DOWN.name,
      duration: Duration(seconds: 10),
      marker: "VEOG");
  static final ProtocolPart _downUp = ProtocolPart(
      state: EyesMovementState.MOVE_DOWN_UP.name,
      duration: Duration(seconds: 10),
      marker: "VEOG");
  static final List<ProtocolPart> _protocolBlock = [_rest, _blink, _blackScreen,
    _leftRight, _blackScreen, _upDown, _blackScreen];

  @override
  ProtocolType get type => ProtocolType.eyes_movement;

  @override
  String get nameForUser => "Eyes Movement";

  @override
  Duration get minDuration => _minDurationOverride ?? Duration(minutes: 5);

  @override
  Duration get maxDuration => _maxDurationOverride ?? Duration(minutes: 5);

  @override
  Duration get disconnectTimeoutDuration => Duration(seconds: 20);

  @override
  String get description => 'Eyes Movement';

  @override
  String get intro => 'Eyes Movement protocol intro';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;
}

ProtocolType protocolTypeFromString(String typeStr) {
  return ProtocolType.values.firstWhere((element) => element.name == typeStr,
      orElse: () => ProtocolType.unknown);
}

ProtocolState protocolStateFromString(String protocolStateStr) {
  return ProtocolState.values.firstWhere(
      (element) => element.name == protocolStateStr,
      orElse: () => ProtocolState.unknown);
}