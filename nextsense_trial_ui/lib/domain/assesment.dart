import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum AssessmentKey {
  day,
  type,
  time
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
      protocol = Protocol.create(protocolType)
        ..setStartTime(startTime);
    }
    else {
      _logger.log(Level.SEVERE, 'Unknown protocol "$protocolTypeString"');
    }

  }

  dynamic getValue(AssessmentKey assessmentKey) {
    return getValues()[assessmentKey.name];
  }

  void setValue(AssessmentKey assessmentKey, dynamic value) {
    getValues()[assessmentKey.name] = value;
  }


}