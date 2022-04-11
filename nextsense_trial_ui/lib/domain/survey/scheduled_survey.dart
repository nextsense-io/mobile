import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum ScheduledSurveyKey {
  survey,
  status,
  period,
  data
}

class ScheduledSurvey extends FirebaseEntity<ScheduledSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSurvey');

  final Survey survey;

  late StudyDay day;

  SurveyState get state =>
      surveyStateFromString(getValue(ScheduledSurveyKey.status));

  SurveyPeriod get period =>
      surveyPeriodFromString(getValue(ScheduledSurveyKey.period));

  bool get isCompleted => state == SurveyState.completed;
  bool get isSkipped => state == SurveyState.skipped;

  ScheduledSurvey(FirebaseEntity firebaseEntity, this.survey, this.day) :
        super(firebaseEntity.getDocumentSnapshot());

  // Set state of protocol in firebase
  void setState(SurveyState state) {
    setValue(ScheduledSurveyKey.status, state.name);
  }

  void setPeriod(SurveyPeriod period) {
    setValue(ScheduledSurveyKey.period, period.name);
  }

  // Save submitted survey data
  void setData(Map<String, dynamic> data) {
    setValue(ScheduledSurveyKey.data, data);
  }

  // Survey didn't start in time, should be skipped
  bool isLate() {
    if (state != SurveyState.not_started)
      return false;
    final currentTime = DateTime.now();
    switch (period) {
      case SurveyPeriod.daily:
        // Daily survey ends at 00:00
        return currentTime
            .isAfter(day.closestFutureMidnight.subtract(Duration(seconds: 1)));
      case SurveyPeriod.certain_day:
      // TODO(alex): Handle this case. Implement grace period.
        break;
      case SurveyPeriod.weekly:
      // TODO(alex): Handle this case. Implement grace period.
        break;
      default:
        break;
    }
    return false;
    /*return state == SurveyState.not_started
        && currentTime.isAfter(allowedStartBefore.subtract(Duration(seconds: 1)));*/
  }

  // Update fields and save to firestore by default
  @override
  bool update({required SurveyState state,
    Map<String, dynamic>? data, bool persist = true}) {
    if (this.state == SurveyState.completed) {
      _logger.log(Level.INFO, 'Survey ${survey.name} already completed.'
          'Cannot change its state.');
      return false;
    }
    else if (this.state == SurveyState.skipped) {
      _logger.log(Level.INFO, 'Survey ${survey.name} already skipped.'
          'Cannot change its state.');
      return false;
    }
    _logger.log(Level.WARNING,
        'Survey state changing from ${this.state} to $state');
    setState(state);

    if (data != null) {
      setData(data);
    }
    if (persist) {
      save();
    }
    return true;
  }


}