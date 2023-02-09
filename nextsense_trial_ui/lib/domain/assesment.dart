import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/survey_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

enum PlannedAssessmentKey {
  allowed_early_start_time_minutes,  // How many minutes the protocol can be started before the time
  allowed_late_start_time_minutes,  // How many minutes the protocol can be started after the time.
  day,  // Specific day where the assessment should be taken. If periodic, first day offset.
  end_day,  // Last day where the assessment will be scheduled when it is periodic.
  parameters,  // Key/value map of assessment specific parameters (by type).
  period,  // Period of the assessment defined in Period enum.
  post_surveys,  // List of surveys that can be ran after the protocol is finished.
  time,  // Specific time at which the assessment should be started.
  type,  // Defined by the ProtocolType enum. Type of the protocol like sleep, biocalibration etc.
}

enum PlannedAssessmentParameter {
  minDuration,
  maxDuration
}

class PlannedAssessment extends FirebaseEntity<PlannedAssessmentKey> {

  final SurveyManager _surveyManager = getIt<SurveyManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('Assessment');

  // Start time string in format "HH:MM".
  late String startTimeStr;
  // Contains only time part.
  late DateTime startTime;
  late List<Survey> postSurveys;
  late int allowedEarlyStartTimeMinutes;
  late int allowedLateStartTimeMinutes;
  late Protocol? protocol;
  late PlannedActivity _plannedActivity;

  // defaults to specific day for legacy assessments where it was not set.
  Period get _period => Period.fromString(getValue(PlannedAssessmentKey.period));
  int? get _dayNumber => getValue(PlannedAssessmentKey.day);
  int? get _lastDayNumber => getValue(PlannedAssessmentKey.end_day);
  List<StudyDay> get days => _plannedActivity.days;

  PlannedAssessment(FirebaseEntity firebaseEntity, DateTime studyStartDate, DateTime studyEndDate) :
        super(firebaseEntity.getDocumentSnapshot()) {
    if (_dayNumber == null || !(_dayNumber is int)) {
      throw("'day' is not set or not number in planned assessment");
    }
    _plannedActivity = PlannedActivity(_period, _dayNumber, _lastDayNumber, studyStartDate,
        studyEndDate);
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
          _logger.log(Level.SEVERE, "Survey $surveyId not found.");
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