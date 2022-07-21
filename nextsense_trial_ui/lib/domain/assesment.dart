import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedAssessmentKey {
  day,
  type,
  time,
  parameters,
  allowed_early_start_time_minutes,
  allowed_late_start_time_minutes,
  post_surveys
}

enum PlannedAssessmentParameter {
  minDuration,
  maxDuration
}

class PlannedAssessment extends FirebaseEntity<PlannedAssessmentKey> {

  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('Assessment');

  late StudyDay day;

  // Get day # of study
  int get dayNumber => day.dayNumber;

  // Start time string in format "HH:MM"
  late String startTimeStr;

  // Contains only time part
  late DateTime startTime;

  // Returns absolute datetime of protocol start
  DateTime get startDateTime => day.date.add(
      Duration(hours: startTime.hour, minutes: startTime.minute));

  // Returns start date in format "YYYY-MM-DD"
  String get startDateAsString => startDateTime.toString().split(" ")[0];

  // Returns start datetime in format "YYYY-MM-DD HH:MM"
  String get startDateTimeAsString => startDateTime.toString();

  late List<Survey> postSurveys;
  late int allowedEarlyStartTimeMinutes;
  late int allowedLateStartTimeMinutes;

  Protocol? protocol;

  PlannedAssessment(FirebaseEntity firebaseEntity, DateTime studyStartDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    final dayNumber = getValue(PlannedAssessmentKey.day);
    if (dayNumber == null || !(dayNumber is int)) {
      throw("'day' is not set or not number in planned assessment");
    }
    day = StudyDay(
        studyStartDate.add(Duration(days: dayNumber - 1)),
        dayNumber
    );
    startTimeStr = getValue(PlannedAssessmentKey.time) as String;
    // TODO(alex): check HH:MM string is correctly set
    int startTimeHours = int.parse(startTimeStr.split(":")[0]);
    int startTimeMinutes = int.parse(startTimeStr.split(":")[1]);
    startTime = DateTime(0, 0, 0, startTimeHours, startTimeMinutes);

    allowedEarlyStartTimeMinutes =
        getValue(PlannedAssessmentKey.allowed_early_start_time_minutes) ?? 0;
    allowedLateStartTimeMinutes =
        getValue(PlannedAssessmentKey.allowed_late_start_time_minutes) ?? 0;

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
          protocolType,
          startTime: startTime,
          minDuration: minDurationOverride,
          maxDuration: maxDurationOverride
      );
      List<Survey> surveys = [];
      for (String surveyId in getValue(PlannedAssessmentKey.post_surveys) ?? []) {
        Survey? survey = _surveyManager.getSurveyById(surveyId);
        if (survey == null) {
          _logger.log(Level.SEVERE, "Survey ${surveyId} not found.");
          continue;
        }
        surveys.add(survey);
      }
      postSurveys = surveys;
      _logger.log(Level.INFO, postSurveys);
    } else {
      _logger.log(Level.WARNING, 'Unknown protocol "$protocolTypeString"');
    }
  }

  Duration? getDurationOverride(String field) {
    dynamic value = getParameters()[field];
    if (value == null) {
      return null;
    }
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