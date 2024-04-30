// Defines the list of existing protocols and common properties of each.
import 'package:flutter_common/domain/protocol.dart';

enum ProtocolType {
  variable_daytime,  // Daytime recording of variable length
  sleep,  // Nighttime sleep recording
  eoec,  // Eyes-Open, Eyes-Closed recording
  erp_audio,  // Event-Related Potential using audio recording
  eyes_movement, // Eyes movement recording
  nap,  // Nap recording.
  bio_calibration,  // Bio Calibration recording
  unknown
}

abstract class TrialProtocol extends Protocol {

  ProtocolType get protocolType;

  factory TrialProtocol(ProtocolType type,
      {DateTime? startTime, Duration? minDuration, Duration? maxDuration}) {
    TrialBaseProtocol protocol;
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
      case ProtocolType.bio_calibration:
        protocol = BioCalibrationProtocol();
        break;
      case ProtocolType.erp_audio:
        protocol = ERPAudioProtocol();
        break;
      default:
        print("Class for protocol type $type isn't defined");
        return VariableDaytimeProtocol();
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

  @override
  String get type => ProtocolType.unknown.name;
}

abstract class TrialBaseProtocol extends BaseProtocol implements TrialProtocol {

  @override
  String get type => protocolType.name;

}

class VariableDaytimeProtocol extends TrialBaseProtocol {

  @override
  ProtocolType get protocolType => ProtocolType.variable_daytime;

  @override
  String get nameForUser => "Daytime";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 0);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(hours: 24);

  @override
  String get description => 'Record at daytime';

  @override
  String get intro => 'Records for a variable amount of time at daytime.'
      ' You can stop the recording at any time.';

  @override
  Duration get disconnectTimeoutDuration => const Duration(hours: 24);
}

class SleepProtocol extends TrialBaseProtocol {

  @override
  ProtocolType get protocolType => ProtocolType.sleep;

  @override
  String get nameForUser => 'Sleep';

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 0);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(hours: 12);

  @override
  String get description => 'Sleep';

  @override
  String get intro => 'Lay down in bed to get ready for your night then press the start button.';
}

class NapProtocol extends TrialBaseProtocol {

  @override
  ProtocolType get protocolType => ProtocolType.nap;

  @override
  String get nameForUser => 'Nap';

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 0);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(hours: 4);

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

class EyesOpenEyesClosedProtocol extends TrialBaseProtocol {

  static final ProtocolPart _eyesOpen = ProtocolPart(
      state: EOECState.EO.name,
      duration: const Duration(seconds: 60),
      marker: EOECState.EO.name);
  static final ProtocolPart _eyesClosed = ProtocolPart(
      state: EOECState.EC.name,
      duration: const Duration(seconds: 60),
      marker: EOECState.EC.name);
  static final List<ProtocolPart> _protocolBlock = [_eyesOpen, _eyesClosed];

  @override
  ProtocolType get protocolType => ProtocolType.eoec;

  @override
  String get nameForUser => "Eyes Open, Eyes Closed";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 4);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(minutes: 4);

  @override
  Duration get disconnectTimeoutDuration => const Duration(seconds: 20);

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

enum ERPAudioState {
  NORMAL_SOUND,
  ODD_SOUND,
  PLAY_SOUND,
  RESPONSE_WINDOW,
  BREAK,
  BUTTON_PRESS,
  CORRECT_RESPONSE,
  WRONG_RESPONSE
}

class ERPAudioProtocol extends TrialBaseProtocol {

  // Placeholder to play a random sound. 4/5 is normal, 1/5 is odd.
  static final ProtocolPart playSound = ProtocolPart(
      state: ERPAudioState.PLAY_SOUND.name,
      duration: const Duration(milliseconds: 100),
      marker: ERPAudioState.PLAY_SOUND.name);
  static final ProtocolPart normalSound = ProtocolPart(
      state: ERPAudioState.NORMAL_SOUND.name,
      duration: const Duration(milliseconds: 100),
      marker: ERPAudioState.NORMAL_SOUND.name);
  static final ProtocolPart oddSound = ProtocolPart(
      state: ERPAudioState.ODD_SOUND.name,
      duration: const Duration(milliseconds: 100),
      marker: ERPAudioState.ODD_SOUND.name);
  static final ProtocolPart _responseWindow = ProtocolPart(
      state: ERPAudioState.RESPONSE_WINDOW.name,
      duration: const Duration(milliseconds: 1000),
      marker: ERPAudioState.RESPONSE_WINDOW.name);
  static final ProtocolPart _break = ProtocolPart(
      state: ERPAudioState.BREAK.name,
      duration: const Duration(milliseconds: 200),
      durationVariation: const Duration(milliseconds: 400),
      marker: ERPAudioState.BREAK.name);
  static final List<ProtocolPart> _protocolBlock = [
    playSound, _responseWindow, _break, playSound, _responseWindow, _break, playSound,
    _responseWindow,  _break, playSound, _responseWindow, _break, playSound, _responseWindow,
    _break
  ];

  @override
  ProtocolType get protocolType => ProtocolType.erp_audio;

  @override
  String get nameForUser => "P-300 ERP Audio";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 6);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(minutes: 6);

  @override
  Duration get disconnectTimeoutDuration => const Duration(seconds: 0);

  @override
  String get description => 'P-300 Event-Related Potential (ERP) Audio';

  @override
  String get intro =>
      'IMPORTANT: Make sure the sound is perceivable and adjust the volume if needed.\n\n'
      'You will hear a series of beeps.\n\n'
      'When the lower beep is played, immediately press the button to respond.\n\n'
      'Respond only to the lower beep.\n';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;

  @override
  int? get blocksPerBreak => 10;
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

class EyesMovementProtocol extends TrialBaseProtocol {

  static final ProtocolPart _rest = ProtocolPart(
      state: EyesMovementState.REST.name,
      duration: const Duration(seconds: 15),
      marker: "REST");
  static final ProtocolPart _blackScreen = ProtocolPart(
      state: EyesMovementState.BLACK_SCREEN.name,
      duration: const Duration(seconds: 5),
      marker: "REST");
  static final ProtocolPart _blink = ProtocolPart(
      state: EyesMovementState.BLINK.name,
      duration: const Duration(seconds: 10),
      marker: "BLINKS");
  static final ProtocolPart _rightLeft = ProtocolPart(
      state: EyesMovementState.MOVE_RIGHT_LEFT.name,
      duration: const Duration(seconds: 10),
      marker: "HEOG");
  static final ProtocolPart _leftRight = ProtocolPart(
      state: EyesMovementState.MOVE_LEFT_RIGHT.name,
      duration: const Duration(seconds: 10),
      marker: "HEOG");
  static final ProtocolPart _upDown = ProtocolPart(
      state: EyesMovementState.MOVE_UP_DOWN.name,
      duration: const Duration(seconds: 10),
      marker: "VEOG");
  static final ProtocolPart _downUp = ProtocolPart(
      state: EyesMovementState.MOVE_DOWN_UP.name,
      duration: const Duration(seconds: 10),
      marker: "VEOG");
  static final List<ProtocolPart> _protocolBlock = [_rest, _blink, _blackScreen,
    _leftRight, _blackScreen, _upDown, _blackScreen];

  @override
  ProtocolType get protocolType => ProtocolType.eyes_movement;

  @override
  String get nameForUser => "Eyes Movement";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 5);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(minutes: 5);

  @override
  Duration get disconnectTimeoutDuration => const Duration(seconds: 20);

  @override
  String get description => 'Eyes Movement';

  @override
  String get intro => 'Eyes Movement protocol intro';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;
}

enum BioCalibrationState {
  UNKNOWN,
  NOT_RUNNING,
  REST,  // Rest period.
  BLACK_SCREEN,  // Show black screen between activities.
  BLINK,  // Blink eyes.
  MOVE_HORIZONTAL,  // Moves eyes back and forth horizontally.
  MOVE_VERTICAL,  // Moves eyes back and forth vertically.
  JAW_CLENCH  // Clench the jaws.
}

class BioCalibrationProtocol extends TrialBaseProtocol {

  static final ProtocolPart _rest = ProtocolPart(
      state: BioCalibrationState.REST.name,
      duration: const Duration(seconds: 15),
      marker: "REST");
  static final ProtocolPart _blink = ProtocolPart(
      state: BioCalibrationState.BLINK.name,
      duration: const Duration(seconds: 10),
      marker: "BLINKS");
  static final ProtocolPart _horizontal = ProtocolPart(
      state: BioCalibrationState.MOVE_HORIZONTAL.name,
      duration: const Duration(seconds: 10),
      marker: "HEOG");
  static final ProtocolPart _vertical = ProtocolPart(
      state: BioCalibrationState.MOVE_VERTICAL.name,
      duration: const Duration(seconds: 10),
      marker: "VEOG");
  static final ProtocolPart _jawClench = ProtocolPart(
      state: BioCalibrationState.JAW_CLENCH.name,
      duration: const Duration(seconds: 15),
      marker: "CLENCH");
  static final List<ProtocolPart> _protocolBlock =
      [_rest, _blink, _horizontal, _vertical, _jawClench];

  @override
  ProtocolType get protocolType => ProtocolType.bio_calibration;

  @override
  String get nameForUser => "Bio Calibration";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 2);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(minutes: 2);

  @override
  Duration get disconnectTimeoutDuration => const Duration(seconds: 20);

  @override
  String get description => 'Bio Calibration';

  @override
  String get intro => 'Before the recording\n' +
      'If you’re not already wearing them, put on the earbuds.\n'
      'Earbuds needs to be worn for at least 10 minutes before starting the recording to allow '
      'electrodes to settle.\n\n'
      'During the recording\n'
      ' - Do not move\n'
      ' - Relax\n'
      ' - Follow the instructions on the screen\n';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;
}

enum GenericStates {
  USER_BREAK,
}

final ProtocolPart userBreak = ProtocolPart(
    state: GenericStates.USER_BREAK.name,
    duration: const Duration(seconds: 0),
    marker: "USER_BREAK");

ProtocolType protocolTypeFromString(String typeStr) {
  return ProtocolType.values.firstWhere((element) => element.name == typeStr,
      orElse: () => ProtocolType.unknown);
}
