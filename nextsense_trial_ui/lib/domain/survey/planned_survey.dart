import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

enum PlannedSurveyKey {
  day,
  survey,
  days_to_complete,
  period
}

class PlannedSurvey extends FirebaseEntity<PlannedSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('PlannedSurvey');

  // Days on which survey will appear
  List<StudyDay> days = [];

  String get surveyId => getValue(PlannedSurveyKey.survey);

  SurveyPeriod get period =>
      surveyPeriodFromString(getValue(PlannedSurveyKey.period));

  late int daysToComplete;
  int? specificDayNumber;

  PlannedSurvey(FirebaseEntity firebaseEntity, DateTime studyStartDate,
      DateTime studyEndDate) :
        super(firebaseEntity.getDocumentSnapshot()) {

    // We have following possible values for period field
    // 1. 'specific_day' - survey will take place certain day within study
    // 2. 'daily' - survey will take place each day of study
    // 3. 'weekly' - survey will take place on 8th day, 15th, etc.
    if (period == SurveyPeriod.specific_day) {
      specificDayNumber = getValue(PlannedSurveyKey.day);
    }

    _initSurveyDays(studyStartDate, studyEndDate);
    _initSurveyStartGracePeriod();

  }

  void _initSurveyStartGracePeriod() {
    int? _daysToComplete = getValue(PlannedSurveyKey.days_to_complete);
    if (_daysToComplete != null) {
      daysToComplete = _daysToComplete;
    } else {
      // Default values for grace period
      daysToComplete = 1;
      switch (period) {
        case SurveyPeriod.weekly:
          daysToComplete = 7;
          break;
        default:
          break;
      }
    }
  }

  // Create list of study days according to period of survey
  void _initSurveyDays(DateTime studyStartDate,
      DateTime studyEndDate) {

    if (period == SurveyPeriod.specific_day) {
      // For certain day number we just add single day
      days.add(StudyDay(
          studyStartDate.add(Duration(days: specificDayNumber! - 1)),
          specificDayNumber!));
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
      dayNumber += dayIncrement;
    }
  }
}
