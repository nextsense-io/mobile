import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedSurveyKey {
  day,
  survey
}

enum PlannedSurveyPeriod {
  daily,
  weekly
}

class PlannedSurvey extends FirebaseEntity<PlannedSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedSurvey');

  // Days on which survey will appear
  List<StudyDay> days = [];

  String get surveyId => getValue(PlannedSurveyKey.survey);

  PlannedSurvey(FirebaseEntity firebaseEntity, DateTime studyStartDate,
      DateTime studyEndDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    dynamic day = getValue(PlannedSurveyKey.day);

    // We have following possible values for day field
    // 1. day number - survey will take place certain day within study
    // 2. 'daily' - survey will take place each day of study
    // 3. 'weekly' - survey will take place on 8th, 15th, etc.
    print(day.runtimeType);
    if (day is int) {
      // For certain day number we just add single day
      days.add(
          StudyDay(studyStartDate.add(Duration(days: day - 1)), day)
      );
    }
    else if (day is String) {
      DateTime currentDate = studyStartDate;
      // This date represents closest 00:00 after study end date
      // TODO(alex): check if already midnight
      DateTime studyEndDateMidnight = DateTime(
          studyEndDate.year,
          studyEndDate.month,
          studyEndDate.day + 1
      );
      int dayIncrement;
      int dayNumber = 1;
      if (day == PlannedSurveyPeriod.daily.name) {
        dayIncrement = 1;
      } else if (day == PlannedSurveyPeriod.weekly.name) {
        // Weekly surveys start on day 8, 15 etc.
        dayIncrement = 7;
        currentDate = currentDate.add(Duration(days: dayIncrement));
      }
      else {
        _logger.log(Level.WARNING, 'Invalid day value "$day"');
        return;
      }
      while (currentDate.isBefore(studyEndDateMidnight)) {
        days.add(StudyDay(currentDate, dayNumber));
        currentDate = currentDate.add(Duration(days: dayIncrement));
        dayNumber+=1;
      }
    }
  }

}