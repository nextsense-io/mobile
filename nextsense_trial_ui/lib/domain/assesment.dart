import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum AssessmentKey {
  day,
  type,
  time,
  parameters
}

class Assessment extends FirebaseEntity {

  final CustomLogPrinter _logger = CustomLogPrinter('Assessment');

  late int dayNumber;

  late DateTime day;

  Protocol? protocol;

  Assessment(FirebaseEntity firebaseEntity, DateTime studyStartDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    dayNumber = getValue(AssessmentKey.day);
    day = studyStartDate.add(Duration(days: dayNumber - 1));
    final startTimeStr = getValue(AssessmentKey.time) as String;
    // TODO(alex): check HH:MM string is correctly set
    final startTimeHours = int.parse(startTimeStr.split(":")[0]);
    final startTimeMinutes = int.parse(startTimeStr.split(":")[1]);
    final startTime = DateTime(0, 0, 0, startTimeHours, startTimeMinutes);

    // Construct protocol here based on assessment fields like
    final protocolTypeString = getValue(AssessmentKey.type);
    final protocolType = Protocol.typeFromString(protocolTypeString);

    if (protocolType != ProtocolType.unknown) {
      // Create protocol assigned to current assessment
      protocol = Protocol.create(protocolType, startTime);

      // Override default min/max durations
      final minDurationOverride = getDurationOverride('minDuration');
      final maxDurationOverride = getDurationOverride('maxDuration');
      if (minDurationOverride != null)
        protocol!.setMinDuration(minDurationOverride);
      if (maxDurationOverride != null)
        protocol!.setMaxDuration(maxDurationOverride);

    }
    else {
      _logger.log(Level.WARNING, 'Unknown protocol "$protocolTypeString"');
    }

  }

  dynamic getValue(AssessmentKey assessmentKey) {
    return getValues()[assessmentKey.name];
  }

  void setValue(AssessmentKey assessmentKey, dynamic value) {
    getValues()[assessmentKey.name] = value;
  }

  Duration? getDurationOverride(String field) {
    dynamic value = getParameters()[field];
    if (value == null)
      return null;
    // Value comes in HH:MM:SS format
    final hms = value.split(":");
    return Duration(
        hours: int.parse(hms[0]),
        minutes: int.parse(hms[1]),
        seconds: int.parse(hms[2]));
  }

  Map<String, dynamic> getParameters() {
    return getValue(AssessmentKey.parameters) ?? {};
  }


}