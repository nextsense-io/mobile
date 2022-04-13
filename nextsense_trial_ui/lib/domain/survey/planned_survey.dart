import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

enum PlannedSurveyKey {
  day,
  survey,
  allowed_late_start_days
}

class PlannedSurvey extends FirebaseEntity<PlannedSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedSurvey');

  // Days on which survey will appear
  List<StudyDay> days = [];

  String get surveyId => getValue(PlannedSurveyKey.survey);

  late SurveyPeriod period;

  late int allowedLateStartDays;
  int? certainDayNumber;

  PlannedSurvey(FirebaseEntity firebaseEntity, DateTime studyStartDate,
      DateTime studyEndDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    dynamic day = getValue(PlannedSurveyKey.day);

    // We have following possible values for day field
    // 1. day number - survey will take place certain day within study
    // 2. 'daily' - survey will take place each day of study
    // 3. 'weekly' - survey will take place on 8th, 15th, etc.

    if (day is int) {
      period = SurveyPeriod.certain_day;
      certainDayNumber = day;
    }
    else if (day is String) {
      if (day == SurveyPeriod.daily.name) {
        period = SurveyPeriod.daily;
      } else if (day == SurveyPeriod.weekly.name) {
        period = SurveyPeriod.weekly;
      } else {
        throw("Invalid day value - $day");
      }
    }
    else {
      throw("Invalid day value - $day");
    }

    _initSurveyDays(studyStartDate, studyEndDate);
    _initSurveyStartGracePeriod();

  }

  void _initSurveyStartGracePeriod() {
    int? _allowedLateStartDays = getValue(PlannedSurveyKey.allowed_late_start_days);
    if (_allowedLateStartDays != null) {
      allowedLateStartDays = _allowedLateStartDays;
    } else {
      // Default values for grace period
      allowedLateStartDays = 1;
      switch (period) {
        case SurveyPeriod.weekly:
          allowedLateStartDays = 7;
          break;
        default:
          break;
      }
    }
  }

  // Create list of study days according to period of survey
  void _initSurveyDays(DateTime studyStartDate,
      DateTime studyEndDate) {

    if (period == SurveyPeriod.certain_day) {
      // For certain day number we just add single day
      days.add(StudyDay(
          studyStartDate.add(Duration(days: certainDayNumber! - 1)),
          certainDayNumber!));
      return;
    }

    DateTime currentDate = studyStartDate;
    // This date represents closest 00:00 after study end date
    // TODO(alex): check if already midnight
    // Default values for 'daily' period
    int dayIncrement = 1;
    int dayNumber = 1;
    if (period == SurveyPeriod.weekly) {
      // Weekly surveys start on day 8, 15 etc.
      dayIncrement = 7;
      dayNumber = 8;
      currentDate = currentDate.add(Duration(days: dayIncrement));
    }
    while (currentDate.isBefore(studyEndDate.closestFutureMidnight)) {
      days.add(StudyDay(currentDate, dayNumber));
      currentDate = currentDate.add(Duration(days: dayIncrement));
      dayNumber+=dayIncrement;
    }
  }

}