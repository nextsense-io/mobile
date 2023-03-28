import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';

enum AdhocSurveyKey {
  planned_survey_id,
  result_id  // Survey record id
}

class AdhocSurvey extends FirebaseEntity<AdhocSurveyKey> implements RunnableSurvey {
  late String plannedSurveyId;
  late Survey survey;
  late String studyId;

  ScheduleType get scheduleType => ScheduleType.adhoc;
  String? get resultId => getValue(AdhocSurveyKey.result_id);
  String? get scheduledSurveyId => null;

  AdhocSurvey(FirebaseEntity firebaseEntity, this.plannedSurveyId, this.survey, this.studyId)
      : super(firebaseEntity.getDocumentSnapshot());

  void setPlannedSurveyId(String plannedSurveyId) {
    setValue(AdhocSurveyKey.planned_survey_id, plannedSurveyId);
  }

  void setResultId(String resultId) {
    setValue(AdhocSurveyKey.result_id, resultId);
  }

  @override
  Future<bool> update({required SurveyState state, required String resultId}) async {
    setPlannedSurveyId(survey.id);
    setResultId(resultId);
    return await save();
  }
}
