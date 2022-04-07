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
  status
}

class ScheduledSurvey extends FirebaseEntity<ScheduledSurveyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('ScheduledSurvey');

  final Survey survey;

  late StudyDay day;

  SurveyState get state =>
      surveyStateFromString(getValue(ScheduledSurveyKey.status));

  bool get isCompleted => state == SurveyState.completed;
  bool get isSkipped => state == SurveyState.skipped;

  ScheduledSurvey(FirebaseEntity firebaseEntity, this.survey, this.day) :
        super(firebaseEntity.getDocumentSnapshot());

  // Set state of protocol in firebase
  void setState(SurveyState state) {
    setValue(ScheduledSurveyKey.status, state.name);
  }

  // Update fields and save to firestore by default
  @override
  bool update({required SurveyState state,
    String? sessionId, bool persist = true}) {
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
    if (persist) {
      save();
    }
    return true;
  }

}