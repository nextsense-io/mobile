import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';

enum ScheduleType {
  scheduled,  // Session is scheduled at specific time/frequency.
  adhoc,  // Session can be started at any time.
  conditional; // Session is started based on some condition.

  factory ScheduleType.fromString(String scheduleTypeStr) {
    return ScheduleType.values.firstWhere((element) => element.name == scheduleTypeStr);
  }
}

abstract class Schedulable {
  ScheduleType get scheduleType;
  String? get triggersConditionalSessionId;
  String? get triggersConditionalSurveyId;
}

enum Period {
  specific_day,
  daily,
  weekly,
  unknown;

  factory Period.fromString(String? periodStr) {
    return Period.values.firstWhere((element) => element.name == periodStr,
        orElse: () => Period.unknown);
  }
}

class PlannedActivity {
  static const int defaultDailyStartDay = 1;
  static const int defaultWeeklyStartDay = 8;

  final Period _period;
  final int? _specificDayNumber;
  final int? _lastDayNumber;
  // List of study days in which the activity is planned.
  late List<StudyDay> days = [];


  PlannedActivity(Period period, int? specificDayNumber, int? lastDayNumber,
      DateTime studyStartDate, DateTime studyEndDate) :
        _period = period, _specificDayNumber = specificDayNumber, _lastDayNumber = lastDayNumber {
    _initDays(studyStartDate, studyEndDate);
  }

  // Create list of study days according to period of survey.
  void _initDays(DateTime studyStartDate, DateTime studyEndDate) {
    if (_period == Period.unknown) {
      return;
    }
    if (_period == Period.specific_day) {
      // For certain day number we just add single day
      days.add(StudyDay(
          studyStartDate.add(Duration(days: _specificDayNumber! - 1)), _specificDayNumber!));
      return;
    }

    // Default values for 'daily' period.
    int dayNumber = _specificDayNumber ?? defaultDailyStartDay;
    int dayIncrement = 1;
    if (_period == Period.weekly) {
      // Weekly surveys start on day 8, 15 etc.
      dayIncrement = 7;
      dayNumber = _specificDayNumber ?? defaultWeeklyStartDay;
    }
    DateTime currentDate = studyStartDate.add(Duration(days: dayNumber - 1));
    do {
      days.add(StudyDay(currentDate, dayNumber));
      currentDate = currentDate.add(Duration(days: dayIncrement));
      dayNumber += dayIncrement;
      if (_lastDayNumber != null && dayNumber > _lastDayNumber!) {
        return;
      }
      // This date represents 23:59 at study end date.
      // TODO(alex): check if already midnight
    } while (currentDate.isBefore(studyEndDate.closestFutureMidnight));
  }
}