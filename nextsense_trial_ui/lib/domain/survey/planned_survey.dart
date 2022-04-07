import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedSurveyKey {
  day,
  survey
}

class PlannedSurvey extends FirebaseEntity<PlannedSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedSurvey');

  late int dayNumber;
  late StudyDay day;

  String get surveyId => getValue(PlannedSurveyKey.survey);

  PlannedSurvey(FirebaseEntity firebaseEntity, DateTime studyStartDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    dayNumber = getValue(PlannedSurveyKey.day);
    day = StudyDay(studyStartDate.add(Duration(days: dayNumber - 1)));
  }

}