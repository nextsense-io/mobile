// Defines the list of existing protocols and common properties of each.
import 'package:flutter_common/domain/protocol.dart';

enum ProtocolType {
  variable_daytime,  // Daytime recording of variable length
  sleep,  // Nighttime sleep recording
  nap,  // Nap recording.
  mental_state_audio,  // Play music based on your mental state
  unknown
}

abstract class ConsumerProtocol extends Protocol {

  ProtocolType get protocolType;

  factory ConsumerProtocol(ProtocolType type,
      {DateTime? startTime, Duration? minDuration, Duration? maxDuration}) {
    ConsumerBaseProtocol protocol;
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
      case ProtocolType.mental_state_audio:
        protocol = MentalStateAudioProtocol();
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

abstract class ConsumerBaseProtocol extends BaseProtocol implements ConsumerProtocol {

  @override
  String get type => protocolType.name;

  @override
  String get name => protocolType.name;

}

class VariableDaytimeProtocol extends ConsumerBaseProtocol {

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

class SleepProtocol extends ConsumerBaseProtocol {

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

class NapProtocol extends ConsumerBaseProtocol {

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

enum MentalStateAudioState {
  RELAXED_STATE,
  ALERT_STATE,
  PLAYING_SOUND
}

class MentalStateAudioProtocol extends ConsumerBaseProtocol {

  static final ProtocolPart playingSound = ProtocolPart(
      state: MentalStateAudioState.PLAYING_SOUND.name,
      duration: const Duration(milliseconds: 1000 * 10),
      marker: MentalStateAudioState.PLAYING_SOUND.name);
  static final List<ProtocolPart> _protocolBlock = [
    playingSound, playingSound, playingSound, playingSound, playingSound, playingSound
  ];

  @override
  ProtocolType get protocolType => ProtocolType.mental_state_audio;

  @override
  String get nameForUser => "Mental State Audio";

  @override
  Duration get minDuration => minDurationOverride ?? const Duration(minutes: 0);

  @override
  Duration get maxDuration => maxDurationOverride ?? const Duration(hours: 24);

  @override
  Duration get disconnectTimeoutDuration => const Duration(seconds: 0);

  @override
  String get description => 'Mental-state based music player';

  @override
  String get intro =>
      'IMPORTANT: Make sure the sound is perceivable and adjust the volume if needed.\n\n'
      'Music will play based on your mental state. If you relax and close your eyes you will hear '
      'slower tempo music then if you are alert and open your eyes.';

  @override
  List<ProtocolPart> get protocolBlock => _protocolBlock;
}
ProtocolType protocolTypeFromString(String typeStr) {
  return ProtocolType.values.firstWhere((element) => element.name == typeStr,
      orElse: () => ProtocolType.unknown);
}
