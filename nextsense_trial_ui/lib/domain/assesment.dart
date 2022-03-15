import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedAssessmentKey {
  day,
  type,
  time,
  parameters
}

enum PlannedAssessmentParameter {
  minDuration,
  maxDuration
}

class PlannedAssessment extends FirebaseEntity {

  final CustomLogPrinter _logger = CustomLogPrinter('Assessment');

  late DateTime day;

  late int _dayNumber;

  Protocol? protocol;

  PlannedAssessment(FirebaseEntity firebaseEntity, DateTime studyStartDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    _dayNumber = getValue(PlannedAssessmentKey.day);
    day = studyStartDate.add(Duration(days: _dayNumber - 1));
    String startTimeStr = getValue(PlannedAssessmentKey.time) as String;
    // TODO(alex): check HH:MM string is correctly set
    int startTimeHours = int.parse(startTimeStr.split(":")[0]);
    int startTimeMinutes = int.parse(startTimeStr.split(":")[1]);
    DateTime startTime = DateTime(0, 0, 0, startTimeHours, startTimeMinutes);

    // Construct protocol here based on assessment fields like
    String protocolTypeString = getValue(PlannedAssessmentKey.type);
    ProtocolType protocolType = protocolTypeFromString(protocolTypeString);

    if (protocolType != ProtocolType.unknown) {

      // Override default min/max durations
      Duration? minDurationOverride = getDurationOverride(
          PlannedAssessmentParameter.minDuration.name
      );
      Duration? maxDurationOverride = getDurationOverride(
          PlannedAssessmentParameter.maxDuration.name
      );

      // Create protocol assigned to current assessment
      protocol = Protocol(
          protocolType, startTime,
          minDuration: minDurationOverride,
          maxDuration: maxDurationOverride
      );
    }
    else {
      _logger.log(Level.WARNING, 'Unknown protocol "$protocolTypeString"');
    }
  }

  dynamic getValue(PlannedAssessmentKey assessmentKey) {
    return getValues()[assessmentKey.name];
  }

  void setValue(PlannedAssessmentKey assessmentKey, dynamic value) {
    getValues()[assessmentKey.name] = value;
  }

  Duration? getDurationOverride(String field) {
    dynamic value = getParameters()[field];
    if (value == null)
      return null;
    // Value comes in HH:MM:SS format
    List<String> hms = value.split(":");
    return Duration(
        hours: int.parse(hms[0]),
        minutes: int.parse(hms[1]),
        seconds: int.parse(hms[2]));
  }

  Map<String, dynamic> getParameters() {
    return getValue(PlannedAssessmentKey.parameters) ?? {};
  }
}